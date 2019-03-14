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

  def update_from_json(json, opts = {}, apply_nested_records = true)
    obj = super
    Representations.apply_representations(obj, json)
    obj
  end

  module ClassMethods
    def create_from_json(json, extra_values = {})
      obj = super
      Representations.apply_representations(obj, json)
      obj
    end

    def sequel_to_jsonmodel(objs, opts = {})
      jsons = super

      # Grab all referenced representations and slot them in
      backlink_col = :"#{self.table_name}_id"

      physical_representation_jsons = {}
      digital_representation_jsons = {}

      representations = PhysicalRepresentation.filter(backlink_col => objs.map(&:id)).all
      representations.zip(PhysicalRepresentation.sequel_to_jsonmodel(representations)).each do |sequel_obj, json|
        physical_representation_jsons[sequel_obj[backlink_col]] ||= []
        physical_representation_jsons[sequel_obj[backlink_col]] << json
      end

      representations = DigitalRepresentation.filter(backlink_col => objs.map(&:id)).all
      representations.zip(DigitalRepresentation.sequel_to_jsonmodel(representations)).each do |sequel_obj, json|
        digital_representation_jsons[sequel_obj[backlink_col]] ||= []
        digital_representation_jsons[sequel_obj[backlink_col]] << json
      end

      representations_counts = prepare_counts(objs, physical_representation_jsons, digital_representation_jsons)

      objs.zip(jsons).each do |obj, json|
        json['physical_representations'] = physical_representation_jsons.fetch(obj.id, [])
        json['digital_representations'] = digital_representation_jsons.fetch(obj.id, [])
        json['physical_representations_count'] = representations_counts.fetch(obj.id, {}).fetch('physical_representations_count', 0)
        json['digital_representations_count'] = representations_counts.fetch(obj.id, {}).fetch('digital_representations_count', 0)
      end

      jsons
    end

    def prepare_counts(objs, physical_representation_jsons, digital_representation_jsons)
      result = {}

      # The Resource
      if self.my_jsonmodel.record_type == self.root_record_type.to_s
        node_type_backlink_col = :"#{self.node_model.table_name}_id"

        root_ids = objs.map(&:id)
        node_ids = self.node_model.filter(:root_record_id => root_ids).select(:id)

        node_physical_representation_counts = {}
        node_digital_representation_counts = {}

        PhysicalRepresentation
          .inner_join(self.node_model.table_name, Sequel.qualify(PhysicalRepresentation.table_name, node_type_backlink_col) => Sequel.qualify(self.node_model.table_name, :id))
          .filter(node_type_backlink_col => node_ids)
          .group_and_count(Sequel.qualify(self.node_model.table_name, :root_record_id)).each do |row|
          node_physical_representation_counts[row[:root_record_id]] = row[:count]
        end

        DigitalRepresentation
          .inner_join(self.node_model.table_name, Sequel.qualify(DigitalRepresentation.table_name, node_type_backlink_col) => Sequel.qualify(self.node_model.table_name, :id))
          .filter(node_type_backlink_col => node_ids)
          .group_and_count(Sequel.qualify(self.node_model.table_name, :root_record_id)).each do |row|
          node_digital_representation_counts[row[:root_record_id]] = row[:count]
        end

        objs.each do |obj|
          result[obj.id] = {
            'physical_representations_count' => node_physical_representation_counts.fetch(obj.id, 0) + physical_representation_jsons.fetch(obj.id, []).length,
            'digital_representations_count' => node_digital_representation_counts.fetch(obj.id, 0) + digital_representation_jsons.fetch(obj.id, []).length,
          }
        end

      # The Archival Object
      else
        objs.each do |obj|
          result[obj.id] = {
            'digital_representations_count' => digital_representation_jsons.fetch(obj.id, []).length,
            'physical_representations_count' => physical_representation_jsons.fetch(obj.id, []).length,
          }
        end
      end

      result
    end
  end


  def self.apply_representations(obj, json)
    # Representations with refs get updated.  Otherwise, create new records.

    backlink = {:"#{obj.class.table_name}_id" => obj.id}

    [
      [PhysicalRepresentation, 'physical_representations', :physical_representation],
      [DigitalRepresentation, 'digital_representations', :digital_representation]
    ].each do |representation_class, representation_property, representation_jsonmodel|
      grouped = json[representation_property].group_by {|rep| rep['existing_ref']}

      ids_to_keep = grouped.keys.compact.map {|ref| JSONModel.parse_reference(ref)[:id]}

      representation_class
        .filter(backlink)
        .filter(Sequel.~(:id => ids_to_keep))
        .each(&:delete)

      # Create the ones that don't exist yet (no ref)
      ASUtils.wrap(grouped.delete(nil)).each do |to_create|
        representation_class.create_from_json(JSONModel(representation_jsonmodel).from_hash(to_create), backlink)
        obj.mark_as_system_modified
      end

      # Update the others
      grouped.each do |ref, to_update|
        # to_update is always a single element array since the ref ensures uniqueness within the set...
        id = JSONModel.parse_reference(ref)[:id]

        representation_class[id].update_from_json(JSONModel(representation_jsonmodel).from_hash(to_update[0]), backlink)
      end
    end
  end

end
