class RAP < Sequel::Model(:rap)
  include ASModel
  corresponds_to JSONModel(:rap)

  set_model_scope :repository

  def update_from_json(json, opts = {}, apply_nested_records = true)
    result = super

    touch_attached_record_mtime

    # When a RAP is edited, we should reapply it down the tree to ensure that
    # everything gets reindexed and versioned.
    DB.open do |db|
      db[:rap_applied].filter(:rap_id => self.id).delete
      self.attached_root_record.propagate_raps!
    end

    result
  end

  def attached_root_record
    if self[:resource_id]
      Resource.get_or_die(self[:resource_id])
    elsif self[:archival_object_id]
      Resource.get_or_die(ArchivalObject.get_or_die(self[:archival_object_id]).root_record_id)
    elsif self[:physical_representation_id]
      archival_object_id = PhysicalRepresentation.get_or_die(self[:physical_representation_id]).archival_object_id
      Resource.get_or_die(ArchivalObject.get_or_die(archival_object_id).root_record_id)
    elsif self[:digital_representation_id]
      archival_object_id = DigitalRepresentation.get_or_die(self[:digital_representation_id]).archival_object_id
      Resource.get_or_die(ArchivalObject.get_or_die(archival_object_id).root_record_id)
    else
      raise "Can't determine root record for #{self}"
    end
  end

  def self.sequel_to_jsonmodel(objs, opts = {})
    jsons = super

    objs.zip(jsons).each do |obj, json|
      json['display_string'] = obj.build_display_string(json)
      RAPs.supported_models.each do |model|
        if obj[:"#{model.table_name}_id"]
          json['attached_to'] = {
            'ref' => model.get_or_die(obj[:"#{model.table_name}_id"]).uri
          }
        end
      end
      if json['attached_to'].nil? && obj[:default_for_repo_id]
        json['attached_to'] = {
          'ref' => JSONModel(:repository).uri_for(obj[:default_for_repo_id])
        }
      end

      json['is_repository_default'] = !!obj[:default_for_repo_id]
    end

    jsons
  end

  def build_display_string(json)
    [
      "%s years" % [json.years.to_s],
      json.open_access_metadata ? "Open metadata" : "Closed Metadata",
      json['access_status'],
      json['access_category'],
    ].join('; ')
  end

  def self.get_default_id
    repo_id = RequestContext.get(:repo_id)
    default = RAP[:default_for_repo_id => repo_id]

    if default.nil?
      default = RAP.create_from_json(JSONModel(:rap).from_hash(
                                       'open_access_metadata' => false,
                                       'access_status' => 'Restricted Access',
                                       'access_category' => 'N/A',
                                       'years' => 100,
                                       'change_description' => 'System default',
                                       'authorised_by' => 'admin',
                                       'change_date' => Date.today.iso8601,
                                       'approved_by' => 'admin',
                                       'internal_reference' => 'SYSTEM_DEFAULT_RAP',
                                     ),
                                    :default_for_repo_id => repo_id)
    end

    default.id
  end

  def touch_attached_record_mtime
    RAPs.supported_models.each do |model|
      if self[:"#{model.table_name}_id"]
        model.update_mtime_for_ids([self[:"#{model.table_name}_id"]])
        model.filter(:id => self[:"#{model.table_name}_id"]).update(:lock_version => Sequel.expr(1) + :lock_version)
      end
    end
  end

  def self.does_movement_affect_raps(parent_uri, node_uris, position)
    changed = false

    parent_ref = JSONModel.parse_reference(parent_uri)

    target_class = if parent_ref.fetch(:type) == 'resource'
                     Resource
                   elsif parent_ref.fetch(:type) == 'archival_object'
                     ArchivalObject
                   else
                     nil
                   end

    resource = if target_class == Resource
                 Resource.get_or_die(parent_ref.fetch(:id))
               else
                 ao = ArchivalObject.get_or_die(parent_ref.fetch(:id))
                 Resource.get_or_die(ao.root_record_id)
               end

    last_applied = resource.last_rap_applied_time

    return false if target_class.nil?
    return false if node_uris.empty?
    return false if JSONModel.parse_reference(node_uris[0]).fetch(:type) != 'archival_object'

    child_ids = node_uris.map {|uri| JSONModel.parse_reference(uri).fetch(:id)}

    DB.open(true) do
      begin
        TreeReordering.new.reorder(target_class, ArchivalObject,
                                   parent_ref.fetch(:id), child_ids,
                                   position)

        changed = resource.last_rap_applied_time != last_applied
      rescue
        Log.exception($!)
        # Move process threw an exception
      ensure
        raise Sequel::Rollback
      end
    end

    changed
  end
end
