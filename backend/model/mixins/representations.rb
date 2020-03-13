module Representations

  extend JSONModel

  def self.included(base)
    @supported_models ||= []
    @supported_models << base

    base.extend(ClassMethods)
  end

  def self.supported_models
    ASUtils.wrap(@supported_models)
  end


  def after_save
    super

    # Ensure the representations attached to this object have the same
    # resource_id as the object's root_record_id.
    # Generally this is not an issue, but it does get execised during
    # a component transfer operation where an archival_object moves
    # to a new resource.
    unless ASUtils.migration_mode?
      DB.open do |db|
        [:physical_representation, :digital_representation].each do |tbl|
          db[tbl].filter(:archival_object_id => self.id)
                 .filter(Sequel.~(:resource_id => self.root_record_id))
                 .update(:resource_id => self.root_record_id)
        end
      end
    end
  end


  def reindex_representations!
    unless ASUtils.migration_mode?
      DB.open do |db|
        ao_ids = [self.id]
        while !ao_ids.empty?
          [:physical_representation, :digital_representation].each do |tbl|
            db[tbl].filter(:archival_object_id => ao_ids).update(:system_mtime => Time.now)
          end

          ao_ids = self.class.filter(:parent_id => ao_ids).select(:id).map(&:id)
        end
      end
    end
  end

  def update_from_json(json, opts = {}, apply_nested_records = true)
    obj = super
    Representations.apply_representations(obj, json, :update)

    reindex_representations!

    obj
  end

  module ClassMethods
    def create_from_json(json, extra_values = {})
      obj = super
      Representations.apply_representations(obj, json, :create)
      obj
    end

    def handle_delete(ids_to_delete)
      backlink_col = :"#{table_name}_id"

      unless PhysicalRepresentation.filter(backlink_col => ids_to_delete).empty? && DigitalRepresentation.filter(backlink_col => ids_to_delete).empty?
          raise ConflictException.new("Record cannot be deleted if linked to representations")
      end

      super
    end


    def sequel_to_jsonmodel(objs, opts = {})
      jsons = super

      if opts[:skip_representations]
        return jsons
      end


      if RequestContext.get(:current_username) == 'search_indexer'
        DB.open do |db|
          all_physrep_counts = db[:physical_representation]
                                 .filter(:archival_object_id => objs.map(&:id))
                                 .group_and_count(:archival_object_id)
                                 .map {|row| [row[:archival_object_id], row[:count]]}.to_h

          all_digrep_counts = db[:digital_representation]
                                .filter(:archival_object_id => objs.map(&:id))
                                .group_and_count(:archival_object_id)
                                .map {|row| [row[:archival_object_id], row[:count]]}.to_h

          deaccessioned_physrep_counts = db[:physical_representation]
                                           .join(:deaccession, Sequel.qualify(:deaccession, :physical_representation_id) => Sequel.qualify(:physical_representation, :id))
                                           .group_and_count(Sequel.qualify(:physical_representation, :archival_object_id))
                                           .map {|row| [row[:archival_object_id], row[:count]]}.to_h

          deaccessioned_digrep_counts = db[:digital_representation]
                                           .join(:deaccession, Sequel.qualify(:deaccession, :digital_representation_id) => Sequel.qualify(:digital_representation, :id))
                                           .group_and_count(Sequel.qualify(:digital_representation, :archival_object_id))
                                           .map {|row| [row[:archival_object_id], row[:count]]}.to_h

          deaccessioned_map = Deaccessioned.build_deaccessioned_map(objs.map(&:id))

          jsons.zip(objs).each do |json, obj|
            json['physical_representations'] = "NOTUSEDBYINDEXER"
            json['digital_representations'] = "ALSONOTUSEDBYINDEXER"

            if deaccessioned_map.fetch(obj.id)
              # This whole AO is deaccessioned.
              json['physical_representations_count'] = 0
              json['digital_representations_count'] = 0
            else
              json['physical_representations_count'] = all_physrep_counts.fetch(obj.id, 0) - deaccessioned_physrep_counts.fetch(obj.id, 0)
              json['digital_representations_count'] = all_digrep_counts.fetch(obj.id, 0) - deaccessioned_digrep_counts.fetch(obj.id, 0)
            end
          end
        end

        return jsons
      end


      # Grab all referenced representations and slot them in
      backlink_col = :"#{self.table_name}_id"

      physical_representation_jsons = {}
      digital_representation_jsons = {}

      representations = PhysicalRepresentation.filter(backlink_col => objs.map(&:id)).all
      representations.zip(PhysicalRepresentation.sequel_to_jsonmodel(representations)).each do |sequel_obj, json|
        physical_representation_jsons[sequel_obj[backlink_col]] ||= []
        physical_representation_jsons[sequel_obj[backlink_col]] << json.to_hash(:trusted)
      end

      representations = DigitalRepresentation.filter(backlink_col => objs.map(&:id)).all
      representations.zip(DigitalRepresentation.sequel_to_jsonmodel(representations)).each do |sequel_obj, json|
        digital_representation_jsons[sequel_obj[backlink_col]] ||= []
        digital_representation_jsons[sequel_obj[backlink_col]] << json.to_hash(:trusted)
      end

      objs.zip(jsons).each do |obj, json|
        json['physical_representations'] = physical_representation_jsons.fetch(obj.id, [])
        json['digital_representations'] = digital_representation_jsons.fetch(obj.id, [])
        json['physical_representations_count'] = physical_representation_jsons.fetch(obj.id, []).reject{|rep| rep['deaccessioned']}.length
        json['digital_representations_count'] = digital_representation_jsons.fetch(obj.id, []).reject{|rep| rep['deaccessioned']}.length
      end

      jsons
    end
  end


  def self.apply_representations(obj, json, mode = nil)
    # Representations with refs get updated.  Otherwise, create new records.

    backlink = {:"#{obj.class.table_name}_id" => obj.id}

    [
      [PhysicalRepresentation, 'physical_representations', :physical_representation],
      [DigitalRepresentation, 'digital_representations', :digital_representation]
    ].each do |representation_class, representation_property, representation_jsonmodel|
      if mode == :create
        grouped = {nil => json[representation_property]}
      else
        grouped = json[representation_property].group_by {|rep| rep['existing_ref']}

        ids_to_keep = grouped.keys.compact.map {|ref| JSONModel.parse_reference(ref)[:id]}

        representation_class
          .filter(backlink)
          .filter(Sequel.~(:id => ids_to_keep))
          .each do |obj|
          obj.delete
        end

        representation_class
          .filter(backlink)
          .filter(Sequel.~(:id => ids_to_keep))
          .each(&:delete)
      end

      # Create the ones that don't exist yet (no ref)
      ASUtils.wrap(grouped.delete(nil)).each do |to_create|
        if ASUtils.migration_mode?
          representation_class.create_from_json(JSONModel(representation_jsonmodel).from_hash(to_create, raise_errors = false, trusted = true),
                                                backlink.merge(:resource_id => obj.root_record_id))
        else
          representation_class.create_from_json(JSONModel(representation_jsonmodel).from_hash(to_create), backlink.merge(:resource_id => obj.root_record_id))
          obj.mark_as_system_modified
        end
      end

      unless mode == :create
        # Update the others
        grouped.each do |ref, to_update|
          # to_update is always a single element array since the ref ensures uniqueness within the set...
          id = JSONModel.parse_reference(ref)[:id]

          representation_class[id].update_from_json(JSONModel(representation_jsonmodel).from_hash(to_update[0]), backlink)
        end
      end
    end

    # Make sure our RAPs are up to date
    Resource.rap_needs_propagate(obj.root_record_id, obj.id)
  end

end
