class ConservationRequest < Sequel::Model(:conservation_request)
  include ASModel
  corresponds_to JSONModel(:conservation_request)

  set_model_scope :repository

  ## Representations

  def add_representations(representation_model, *ids)
    ids = ids.uniq
    backlink_col = :"#{representation_model.table_name}_id"

    DB.open do |db|
      # Clear any existing entries so we don't end up with duplicates
      db[:conservation_request_representations].filter(backlink_col => ids, :conservation_request_id => self.id).delete
      db[:conservation_request_representations].multi_insert(ids.map {|id| {backlink_col => id, :conservation_request_id => self.id}})

      representation_model.update_mtime_for_ids(ids)
    end
  end

  def remove_representations(representation_model, *ids)
    ids = ids.uniq
    backlink_col = :"#{representation_model.table_name}_id"

    DB.open do |db|
      db[:conservation_request_representations].filter(backlink_col => ids, :conservation_request_id => self.id).delete

      representation_model.update_mtime_for_ids(ids)
    end
  end

  def clear_assigned_records(representation_model)
    backlink_col = :"#{representation_model.table_name}_id"

    DB.open do |db|
      ids = db[:conservation_request_representations]
              .filter(:conservation_request_id => self.id)
              .select(backlink_col)
              .map {|row| row[backlink_col]}

      db[:conservation_request_representations]
        .filter(backlink_col => ids,
                :conservation_request_id => self.id)
        .delete

      representation_model.update_mtime_for_ids(ids)
    end
  end


  ## Archival objects

  # {PhysicalRepresentation => [id1, id2, id3], DigitalRepresentation => [id1, id2, id3]}
  def linked_representations(archival_object_ids)
    result = {
      PhysicalRepresentation => [],
      DigitalRepresentation => [],
    }

    DB.open do |db|
      queue = archival_object_ids.clone

      while !queue.empty?
        # For this set of IDs, find any attached representations
        result.keys.each do |representation_type|
          representation_type.filter(:archival_object_id => queue).select(:id).each do |row|
            result.fetch(representation_type) << row[:id]
          end
        end

        # And continue the search with any children of our AO set
        queue = db[:archival_object].filter(:parent_id => queue).select(:id).map {|row| row[:id]}
      end
    end

    result
  end


  def add_archival_objects(*archival_object_ids)
    linked_representations(archival_object_ids).each do |representation_model, ids|
      self.add_representations(representation_model, *ids)
    end
  end

  def remove_archival_objects(*archival_object_ids)
    linked_representations(archival_object_ids).each do |representation_model, ids|
      self.remove_representations(representation_model, *ids)
    end
  end


  ## Resources
  def toplevel_aos_for_resources(resource_ids)
    ArchivalObject
      .filter(:parent_id => nil, :root_record_id => Resource.filter(:id => resource_ids).select(:id))
      .select(:id).map {|row| row[:id]}
  end

  def add_resources(*resource_ids)
    self.add_archival_objects(*toplevel_aos_for_resources(resource_ids))
  end

  def remove_resources(*resource_ids)
    self.remove_archival_objects(*toplevel_aos_for_resources(resource_ids))
  end


  ## Top containers
  def physical_representations_for_top_containers(top_container_ids)
    PhysicalRepresentation
      .find_relationship(:representation_container)
      .find_by_participant_ids(TopContainer, top_container_ids)
      .map {|relationship| relationship[:physical_representation_id]}
  end

  def add_top_containers(*top_container_ids)
    self.add_representations(PhysicalRepresentation, *physical_representations_for_top_containers(top_container_ids))
  end

  def remove_top_containers(*top_container_ids)
    self.remove_representations(PhysicalRepresentation, *physical_representations_for_top_containers(top_container_ids))
  end

  def self.sequel_to_jsonmodel(objs, opts = {})
    jsons = super

    # Produce counts of linked representations
    linked_representation_counts = self
      .join(:conservation_request_representations,
            Sequel.qualify(:conservation_request, :id) => Sequel.qualify(:conservation_request_representations, :conservation_request_id))
      .filter(Sequel.qualify(:conservation_request, :id) => objs.map(&:id))
      .group_and_count(Sequel.qualify(:conservation_request_representations, :conservation_request_id))
      .map {|row| [row[:conservation_request_id], row[:count]]}
      .to_h

    objs.zip(jsons).each do |obj, json|
      json['display_string'] = "CR#{obj.id}"
      json['linked_representation_count'] = linked_representation_counts.fetch(obj.id, 0)
    end

    jsons
  end

  def add_by_ref(*refs)
    refs.map {|ref| JSONModel.parse_reference(ref)}
      .group_by {|parsed| parsed.fetch(:type)}
      .each do |type, type_refs|

      record_ids = type_refs.map {|ref| ref.fetch(:id)}
      case type
          when 'physical_representation'
            self.add_representations(PhysicalRepresentation, *record_ids)
          when 'resource'
            self.add_resources(*record_ids)
          when 'archival_object'
            self.add_archival_objects(*record_ids)
          when 'top_container'
            self.add_top_containers(*record_ids)
          else
            raise "Can't handle refs of type: #{type.inspect}"
      end
    end
  end

  def remove_by_ref(*refs)
    refs.map {|ref| JSONModel.parse_reference(ref)}
      .group_by {|parsed| parsed.fetch(:type)}
      .each do |type, type_refs|

      record_ids = type_refs.map {|ref| ref.fetch(:id)}
      case type
      when 'physical_representation'
        self.remove_representations(PhysicalRepresentation, *record_ids)
      when 'resource'
        self.remove_resources(*record_ids)
      when 'archival_object'
        self.remove_archival_objects(*record_ids)
      when 'top_container'
        self.remove_top_containers(*record_ids)
      else
        raise "Can't handle refs of type: #{type.inspect}"
      end
    end
  end

end
