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
    end
  end

  def remove_representations(representation_model, *ids)
    ids = ids.uniq
    backlink_col = :"#{representation_model.table_name}_id"

    db[:conservation_request_representations].filter(backlink_col => ids, :conservation_request_id => self.id).delete
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

end
