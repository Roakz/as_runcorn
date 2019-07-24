class ConservationRequest < Sequel::Model(:conservation_request)
  include ASModel
  corresponds_to JSONModel(:conservation_request)

  set_model_scope :repository

  def add_representations(representation_model, *ids)
    ids = ids.uniq
    backlink_col = :"#{representation_model.table_name}_id"

    DB.open do |db|
      # Clear any existing entries so we don't end up with duplicates
      db[:conservation_request_representations].filter(backlink_col => ids, :conservation_request_id => self.id).delete
      db[:conservation_request_representations].multi_insert(ids.map {|id| {backlink_col => id, :conservation_request_id => self.id}})
    end
  end

  def add_archival_objects(*archival_object_ids)
    representation_ids = {
      PhysicalRepresentation => [],
      DigitalRepresentation => [],
    }

    DB.open do |db|
      queue = archival_object_ids.clone

      while !queue.empty?
        # For this set of IDs, find any attached representations
        representation_ids.keys.each do |representation_type|
          representation_type.filter(:archival_object_id => queue).select(:id).each do |row|
            representation_ids.fetch(representation_type) << row[:id]
          end
        end

        # And continue the search with any children of our AO set
        queue = db[:archival_object].filter(:parent_id => queue).select(:id).map {|row| row[:id]}
      end
    end

    representation_ids.each do |representation_model, ids|
      self.add_representations(representation_model, *ids)
    end
  end

  def add_resources(*resource_ids)
    top_level_ao_ids = ArchivalObject
                         .filter(:parent_id => nil, :root_record_id => Resource.filter(:id => resource_ids).select(:id))
                         .select(:id).map {|row| row[:id]}

    self.add_archival_objects(*top_level_ao_ids)
  end

  def add_top_containers(*top_container_ids)
    representation_ids = PhysicalRepresentation
                           .find_relationship(:representation_container)
                           .find_by_participant_ids(TopContainer, top_container_ids)
                           .map {|relationship| relationship[:physical_representation_id]}

    self.add_representations(PhysicalRepresentation, *representation_ids)
  end

end
