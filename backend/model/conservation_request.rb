class ConservationRequest < Sequel::Model(:conservation_request)
  include ASModel
  corresponds_to JSONModel(:conservation_request)

  set_model_scope :repository

  define_relationship(:name => :conservation_request_assessment,
                      :json_property => 'assessment',
                      :contains_references_to_types => proc {[Assessment]},
                      :is_array => false)

  def self.create_from_json(json, extra_values = {})
    obj = super

    if ASUtils.migration_mode?
      physrep_ids = Array(json['migration_physical_representations']).map {|ref|
        JSONModel.parse_reference(ref['ref'])[:id]
      }

      obj.add_physical_representations(*physrep_ids)
    end

    obj
  end

  ## Representations

  def add_physical_representations(*ids)
    ids = ids.uniq

    # Clear any existing entries so we don't end up with duplicates
    self.class.db[:conservation_request_representations].filter(:physical_representation_id => ids, :conservation_request_id => self.id).delete
    self.class.db[:conservation_request_representations].multi_insert(ids.map {|id| {:physical_representation_id => id, :conservation_request_id => self.id}})

    PhysicalRepresentation.update_mtime_for_ids(ids)
  end

  def remove_physical_representations(*ids)
    ids = ids.uniq

    self.class.db[:conservation_request_representations].filter(:physical_representation_id => ids, :conservation_request_id => self.id).delete

    PhysicalRepresentation.update_mtime_for_ids(ids)
  end

  # List the refs of all representations attached to this conservation request
  def assigned_representation_refs
    self.class.db[:conservation_request_representations]
      .filter(:conservation_request_id => self.id)
      .filter(Sequel.~(:physical_representation_id => nil))
      .select(:physical_representation_id)
      .map {|row| PhysicalRepresentation.my_jsonmodel.uri_for(row[:physical_representation_id],
                                                              :repo_id => RequestContext.get(:repo_id))}
  end

  def clear_assigned_records
    ids = self.class.db[:conservation_request_representations]
            .filter(:conservation_request_id => self.id)
            .select(:physical_representation_id)
            .map {|row| row[:physical_representation_id]}

    self.class.db[:conservation_request_representations]
      .filter(:physical_representation_id => ids,
              :conservation_request_id => self.id)
      .delete

    PhysicalRepresentation.update_mtime_for_ids(ids)
  end


  def self.clear_physical_representations(physical_representation_ids)
    db[:conservation_request_representations].filter(:physical_representation_id => physical_representation_ids).delete
  end

  def self.handle_delete(ids_to_delete)
    db[:conservation_request_representations].filter(:conservation_request_id => ids_to_delete).delete

    super
  end

  ## Archival objects

  # Returns a set of physical representation IDs
  def linked_physical_representations(archival_object_ids)
    result = []

    queue = archival_object_ids.clone

    while !queue.empty?
      # For this set of IDs, find any attached physical representations
      PhysicalRepresentation.filter(:archival_object_id => queue).select(:id).each do |row|
        result << row[:id]
      end

      # And continue the search with any children of our AO set
      queue = self.class.db[:archival_object].filter(:parent_id => queue).select(:id).map {|row| row[:id]}
    end

    result
  end


  def add_archival_objects(*archival_object_ids)
    self.add_physical_representations(*linked_physical_representations(archival_object_ids))
  end

  def remove_archival_objects(*archival_object_ids)
    self.remove_physical_representations(*linked_physical_representations(archival_object_ids))
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
    self.add_physical_representations(*physical_representations_for_top_containers(top_container_ids))
  end

  def remove_top_containers(*top_container_ids)
    self.remove_physical_representations(*physical_representations_for_top_containers(top_container_ids))
  end

  def self.sequel_to_jsonmodel(objs, opts = {})
    jsons = super

    # Fun edge case: if a linked assessment is deleted, then force our status
    # back to Ready For Review
    jsons.each do |json|
      if json.status == 'Assessment Created' && !json.assessment
        json.status = 'Ready For Review'
      end
    end

    # Produce counts of linked representations
    linked_representation_counts = self
      .join(:conservation_request_representations,
            Sequel.qualify(:conservation_request, :id) => Sequel.qualify(:conservation_request_representations, :conservation_request_id))
      .filter(Sequel.qualify(:conservation_request, :id) => objs.map(&:id))
      .group_and_count(Sequel.qualify(:conservation_request_representations, :conservation_request_id))
      .map {|row| [row[:conservation_request_id], row[:count]]}
      .to_h

    objs.zip(jsons).each do |obj, json|
      json['linked_representation_count'] = linked_representation_counts.fetch(obj.id, 0)
      json['display_string'] = obj.qsa_id_prefixed + ' (' + json['linked_representation_count'].to_s +
                                                     ' item' + (json['linked_representation_count'] == 1 ? '' : 's') + ')'
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
            self.add_physical_representations(*record_ids)
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
        self.remove_physical_representations(*record_ids)
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
