require 'set'

class RAP < Sequel::Model(:rap)
  include ASModel
  corresponds_to JSONModel(:rap)

  set_model_scope :repository

  ACCESS_CATEGORY_CABINET_MATTERS = 'Cabinet matters'
  ACCESS_CATEGORY_NA = 'N/A'

  def update_from_json(json, opts = {}, apply_nested_records = true)
    self.class.apply_forever_closed_access_categories(json)
    self.class.apply_forever_is_too_long_access_categories(json)

    result = super

    touch_attached_record_mtime

    # When a RAP is edited, we should reapply it down the tree to ensure that
    # everything gets reindexed and versioned.
    DB.open do |db|
      db[:rap_applied].filter(:rap_id => self.id).delete
      self.attached_root_record.propagate_raps!
    end

    attached = attached_record
    RAP.force_unpublish_for_restricted(attached.class, attached.id)

    result
  end

  def attached_record
    if self[:resource_id]
      Resource.get_or_die(self[:resource_id])
    elsif self[:archival_object_id]
      ArchivalObject.get_or_die(self[:archival_object_id])
    elsif self[:physical_representation_id]
      PhysicalRepresentation.get_or_die(self[:physical_representation_id])
    elsif self[:digital_representation_id]
      DigitalRepresentation.get_or_die(self[:digital_representation_id])
    else
      raise "Can't determine attached record for #{self}"
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
    apply_forever_is_too_long_access_categories(json)
    super
  end

  def self.apply_forever_closed_access_categories(json)
    # if access_category = 9-13, ensure years is empty
    if AppConfig[:as_runcorn_forever_closed_access_categories].include?(json['access_category'])
      json['years'] = nil
    end
    if json['access_category'] == RAP::ACCESS_CATEGORY_NA
      json['years'] = nil
      json['open_access_metadata'] = false
    end
  end

  def self.apply_forever_is_too_long_access_categories(json)
    # if access_category = 1-8 and years is empty, default years to 100
    if json['years'].nil?
      if !AppConfig[:as_runcorn_forever_closed_access_categories].include?(json['access_category']) && json['access_category'] != RAP::ACCESS_CATEGORY_NA && !json['access_category'].nil?
        json['years'] = 100
        json['years_default_applied'] = true
      else
        json['years_default_applied'] = false
      end
    else
      json['years_default_applied'] = false
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

  def self.deferred_propagations_active?
    RequestContext.active? && !!RequestContext.get(:deferred_rap_propagation_resource_ids)
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

  def self.force_unpublish_for_restricted(model_class, id)
    today = Date.today

    DB.open do |db|
      existence_label_id = BackendEnumSource.id_for_value('date_label', 'existence')

      if model_class == ArchivalObject || model_class == Resource
        rap_id = if model_class == ArchivalObject
                   db[:rap].filter(:archival_object_id => id).select(:id).first[:id]
                 else
                   db[:rap].filter(:resource_id => id).select(:id).first[:id]
                 end

        # check resource first
        resource_id = model_class == Resource ? id : model_class[id][:root_record_id]
        if Resource[resource_id][:publish] == 1
          unless Resource.calculate_unpublishable([resource_id]).empty?
            Resource
              .filter(:id => resource_id)
              .update(:system_mtime => Time.now,
                      :publish => 0,
                      :lock_version => Sequel.expr(1) + :lock_version)
          end
        end

        # Return a set of AO/RAP applied rows that might now be unpublishable
        # after the RAP changes.
        #
        # This deliberately casts a wide net so there may be false positives.
        # For example, we add one to the end date to compensate for cabinet
        # matters that will round up to January 1 of the following year.
        possibly_unpublishable =
          db[:rap_applied]
            .join(:rap, Sequel.qualify(:rap, :id) => Sequel.qualify(:rap_applied, :rap_id))
            .join(:archival_object, Sequel.qualify(:archival_object, :id) => Sequel.qualify(:rap_applied, :archival_object_id))
            .left_join(:date,
                       Sequel.qualify(:archival_object, :id) => Sequel.qualify(:date, :archival_object_id),
                       Sequel.qualify(:date, :label_id) => existence_label_id)
            .filter(Sequel.qualify(:archival_object, :publish) => 1)
            .filter(Sequel.qualify(:rap_applied, :is_active) => 1)
            .filter(Sequel.qualify(:rap, :id) => rap_id)
            .filter(Sequel.~(Sequel.qualify(:rap, :years) => 0))
            .filter(Sequel.qualify(:rap, :open_access_metadata) => 0)
            .where {
          Sequel.|({ Sequel.qualify(:date, :end) => nil },
                   { Sequel.qualify(:rap, :years) => nil },
                   Sequel.lit("(substring(date.end, 1, 4) + rap.years + 1) >= year(curdate())"))
        }.select(Sequel.qualify(:rap, :years),
                 Sequel.qualify(:rap, :access_category_id),
                 Sequel.qualify(:date, :end),
                 Sequel.qualify(:archival_object, :id))

        to_unpublish = []

        possibly_unpublishable.each do |row|
          if row[:end].nil? || row[:years].nil?
            # If the record is undated or years is null (and therefore "always
            # closed") then it shouldn't be published.
            to_unpublish << row[:id]
          else
            # Otherwise, it should be unpublished if the RAP hasn't expired yet.
            rounded_up_end_date = RAPsApplied::RAPApplications.handle_fuzzy_date(row[:end])

            rap_expires = RAPsApplied::RAPApplications.calculate_expiry_date(Integer(row[:years]),
                                                                             rounded_up_end_date,
                                                                             row[:access_category_id])

            if rap_expires >= today
              to_unpublish << row[:id]
            end
          end
        end

        db[:archival_object].filter(:id => to_unpublish).update(:system_mtime => Time.now,
                                                                :publish => 0,
                                                                :lock_version => Sequel.expr(1) + :lock_version)

        Log.info("Unpublished #{to_unpublish.length} records due to RAP update")

      elsif model_class == PhysicalRepresentation || model_class == DigitalRepresentation
        representation = model_class[id]

        # check resource first
        resource_id = representation[:resource_id]
        if Resource[resource_id][:publish] == 1
          unless Resource.calculate_unpublishable([resource_id]).empty?
            Resource
              .filter(:id => resource_id)
              .update(:system_mtime => Time.now,
                      :publish => 0,
                      :lock_version => Sequel.expr(1) + :lock_version)
          end
        end

        return if representation.publish == 0

        backlink_col = :"#{model_class.table_name}_id"
        rap = db[:rap].filter(backlink_col => id).first

        parent_end_date = db[:date]
                            .filter(:archival_object_id => representation.archival_object_id,
                                    :label_id => existence_label_id)
                            .select(:end)
                            .first[:end]

        should_unpublish = false

        if parent_end_date.nil? || rap[:years].nil?
          # If the record is undated or years is null (and therefore "always
          # closed") then it shouldn't be published.
          should_unpublish = true
        else
          # Otherwise, it should be unpublished if the RAP hasn't expired yet.
          rounded_up_end_date = RAPsApplied::RAPApplications.handle_fuzzy_date(parent_end_date)

          rap_expires = RAPsApplied::RAPApplications.calculate_expiry_date(Integer(rap[:years]),
                                                                           rounded_up_end_date,
                                                                           rap[:access_category_id])

          if rap_expires >= today
            should_unpublish = true
          end
        end

        if should_unpublish
          Log.info("Unpublished representation due to RAP update")

          db[model_class.table_name]
            .filter(:id => id)
            .update(:system_mtime => Time.now,
                    :publish => 0,
                    :lock_version => Sequel.expr(1) + :lock_version)
        end
      end
    end
  end

  def self.attach_rap(model_class, id, rap)
    obj = model_class.get_or_die(id)
    json = model_class.to_jsonmodel(obj)
    json['rap_attached'] = rap.to_hash
    obj.update_from_json(json)

    force_unpublish_for_restricted(model_class, id)
  end

  def self.attached_summary_for(record_uri)
    parsed = JSONModel.parse_reference(record_uri)
    repo_id = JSONModel.parse_reference(parsed[:repository])[:id]

    result = {}

    RequestContext.open(:repo_id => repo_id) do
      DB.open(true) do
        begin
          backlink_col = :"#{parsed[:type]}_id"
          dummy_rap = RAP.create_from_json(JSONModel(:rap).from_hash(
            'open_access_metadata' => false,
            'access_category' => 'N/A',
            'years' => nil,
            'internal_reference' => 'DUMMY_RAP',
            ), backlink_col => parsed[:id])

          resource_id = if parsed[:type] == 'resource'
                          parsed[:id]
                        elsif parsed[:type] == 'archival_object'
                          ArchivalObject[parsed[:id]].root_record_id
                        end

          Resource.propagate_raps!(resource_id, parsed[:type] == 'archival_object' ? parsed[:id] : nil)

          db[:rap_applied]
            .filter(:rap_id => dummy_rap.id)
            .filter(:is_active => 1)
            .each do |row|
            if row[:archival_object_id]
              result[:archival_object] ||= {}
              result[:archival_object][:count] ||= 0
              result[:archival_object][:count] += 1
            elsif row[:digital_representation_id]
              result[:digital_representation] ||= {}
              result[:digital_representation][:count] ||= 0
              result[:digital_representation][:count] += 1
            elsif row[:physical_representation_id]
              result[:physical_representation] ||= {}
              result[:physical_representation][:count] ||= 0
              result[:physical_representation][:count] += 1
            end
          end
        rescue
          Log.exception($!)
        ensure
          p result.inspect
          raise Sequel::Rollback
        end
      end
    end

    result
  end
end
