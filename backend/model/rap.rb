require 'set'

class RAP < Sequel::Model(:rap)
  include ASModel
  corresponds_to JSONModel(:rap)

  set_model_scope :repository

  ACCESS_CATEGORY_CABINET_MATTERS = 'Cabinet matters'

  def update_from_json(json, opts = {}, apply_nested_records = true)
    self.class.apply_forever_closed_access_categories(json)

    more_restrictive = update_makes_rap_more_restrictive?(json)

    result = super

    touch_attached_record_mtime

    # When a RAP is edited, we should reapply it down the tree to ensure that
    # everything gets reindexed and versioned.
    DB.open do |db|
      db[:rap_applied].filter(:rap_id => self.id).delete
      self.attached_root_record.propagate_raps!
    end

    if more_restrictive
      self.class.set_attached_unpublished!(self.id)
    end

    result
  end

  def self.set_attached_unpublished!(rap_id)
    # FIXME only where RAP has not expired???
    DB.open do |db|
      RAPs.supported_models.each do |model|
        model_backlink_col = :"#{model.table_name}_id"

        next unless db[:rap_applied].columns.include?(model_backlink_col)

        model
          .filter(:id => db[:rap_applied]
                           .filter(Sequel.qualify(:rap_applied, :rap_id) => rap_id)
                           .filter(Sequel.qualify(:rap_applied, :is_active) => 1)
                           .select(Sequel.qualify(:rap_applied, model_backlink_col)))
          .filter(:publish => 1)
          .update(:publish => 0)
      end
    end
  end

  def update_makes_rap_more_restrictive?(json)
    if json['open_access_metadata']
      false
    else
      self.open_access_metadata == 1
    end
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

  def self.create_from_json(json, opts = {})
    apply_forever_closed_access_categories(json)
    super
  end

  def self.apply_forever_closed_access_categories(json)
    if AppConfig[:as_runcorn_forever_closed_access_categories].include?(json['access_category'])
      json['years'] = nil
    end
  end

  def build_display_string(json)
    metadata_access_status = json.open_access_metadata ? "Open metadata" : "Closed metadata"
    record_access_status = 'Closed records'
    if json.open_access_metadata && json.years == 0 && json.access_category != ACCESS_CATEGORY_CABINET_MATTERS
      record_access_status = 'Open records'
    end

    [
      json.years.nil? || json.years == 0 ? nil : "%s years" % [json.years.to_s],
      metadata_access_status,
      record_access_status,
      json['access_status'],
      json['access_category'],
    ].compact.join('; ')
  end

  def self.get_default_id
    repo_id = RequestContext.get(:repo_id)
    default = RAP[:default_for_repo_id => repo_id]

    if default.nil?
      default = RAP.create_from_json(JSONModel(:rap).from_hash(
                                       'open_access_metadata' => false,
                                       'access_category' => 'N/A',
                                       'years' => nil,
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

  def self.with_deferred_propagations(&block)
    RequestContext.open(:deferred_rap_propagation_resource_ids => Set.new) do
      result = block.call

      RequestContext.get(:deferred_rap_propagation_resource_ids).each do |resource_id|
        Resource.propagate_raps!(resource_id)
      end

      result
    end
  end
end
