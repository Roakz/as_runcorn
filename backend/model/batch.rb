class Batch < Sequel::Model(:batch)
  include ASModel
  corresponds_to JSONModel(:batch)

  set_model_scope :repository

  define_relationship(:name => :batch_action_batch,
                      :json_property => 'actions',
                      :contains_references_to_types => proc {[BatchAction]})

  class UnsupportedModel < StandardError; end
  class InvalidAction < StandardError; end
  class InvalidRef < StandardError; end
  class OperationNotPermitted < StandardError; end


  def self.action_types
    BatchActionHandler.handlers
  end


  def self.statuses
    @statuses ||= ['no_action'] + BackendEnumSource.values_for('runcorn_batch_action_status').map{|m| m.intern}
  end


  def self.models
    @models ||= BackendEnumSource.values_for('runcorn_batch_model').map{|m| m.intern}
  end


  def self.id_column_map
    @column_map ||= models.map{|m| [m, :"#{m}_id"]}.to_h
  end


  def self.id_columns
    id_column_map.values
  end


  def self.id_column_for(model)
    id_column_map[model.intern] or raise UnsupportedModel.new("Unsupported model: #{model}")
  end


  def self.id_column_to_model(col)
    col.to_s.sub(/_id$/, '').intern
  end


  def self.column_for_row(row)
    row.select{|k,v| !v.nil?}.keys.first
  end


  # set this to true at runtime before adding objects to include deaccessioned objects
  def include_deaccessioned(value)
    @include_deaccessioned = !!value
  end


  def include_deaccessioned?
    if !defined?(@include_deaccessioned)
      @include_deaccessioned = false
    end

    @include_deaccessioned
  end


  def self.deaccessionable_models
    @deaccessionable_models ||= {
      :resource => :resource_id,
      :archival_object => :archival_object_id,
      :physical_representation => :physical_representation_id,
      :digital_representation => :digital_representation_id,
    }
  end


  def handle_deaccessions_for_ids(model, *ids)
    return ids if ids.empty?

    if self.include_deaccessioned? || !Batch.deaccessionable_models.has_key?(model.intern)
      return ids
    end

    col = Batch.deaccessionable_models[model.intern]
    ids - Deaccession.filter(col => ids).map{|row| row[col]}
  end


  def handle_deaccessions_for_dataset(model, dataset)
    if self.include_deaccessioned? || !Batch.deaccessionable_models.has_key?(model.intern)
      return dataset
    end

    col = Batch.deaccessionable_models[model.intern]

    dataset.left_join(:deaccession, Sequel.qualify(:deaccession, col) => Sequel.qualify(model.intern, :id))
      .exclude(Sequel.~(col => nil))
  end


  def add_objects(model, *ids)
    id_col = Batch.id_column_for(model)

    ids = ids.uniq

    DB.open do |db|
      ids = handle_deaccessions_for_ids(model, *ids)

      # Clear any existing entries so we don't end up with duplicates
      db[:batch_objects].filter(id_col => ids, :batch_id => self.id).delete
      begin
        db[:batch_objects].multi_insert(ids.map {|id| {id_col => id, :batch_id => self.id}})
        db[:batch].filter(:id => self.id).update(:lock_version => Sequel.expr(1) + :lock_version, :system_mtime => Time.now)
      rescue Sequel::ForeignKeyConstraintViolation
        raise RecordNotFound.new('Attempt to add a non-existent object')
      end
    end
  end


  def remove_objects(model, *ids)
    id_col = Batch.id_column_for(model)

    ids = ids.uniq

    DB.open do |db|
      db[:batch_objects].filter(id_col => ids, :batch_id => self.id).delete
      db[:batch].filter(:id => self.id).update(:lock_version => Sequel.expr(1) + :lock_version, :system_mtime => Time.now)
    end
  end


  def remove_all_objects
    DB.open do |db|
      db[:batch_objects].filter(:batch_id => self.id).delete
      db[:batch].filter(:id => self.id).update(:lock_version => Sequel.expr(1) + :lock_version, :system_mtime => Time.now)
    end
  end


  def self.ref_types_for(model)
    @model_ref_type_map ||= {
      'archival_object' => ['resource', 'archival_object'],
      'physical_representation' => ['resource', 'archival_object', 'top_container', 'physical_representation'],
      'digital_representation' => ['resource', 'archival_object', 'digital_representation'],
    }

    # default to just the model
    @model_ref_type_map.fetch(model, [model])
  end


  def toplevel_aos_for_resources(resource_ids)
    ds = self.handle_deaccessions_for_dataset('archival_object',
                                              ArchivalObject.filter(:parent_id => nil,
                                                                    :root_record_id => Resource.filter(:id => resource_ids).select(:id)))
    ds.select(Sequel.as(Sequel.qualify(:archival_object, :id), :ao_id)).map {|row| row[:ao_id]}
  end


  def objects_for_aos(type, archival_object_ids)
    # type can be archival_object, physical_representation or digital_representation

    result = []

    DB.open do |db|
      queue = self.handle_deaccessions_for_ids('archival_object', *archival_object_ids.clone)

      while !queue.empty?
        if type == 'archival_object'
          result += queue
        else
          # looking for representations
          db[type.intern].filter(:archival_object_id => queue).select(:id).each do |row|
            result << row[:id]
          end
        end

        # And continue the search with any children of our AO set
        queue = self.handle_deaccessions_for_dataset('archival_object', db[:archival_object].filter(:parent_id => queue)).select(:archival_object__id).map {|row| row[:archival_object__id]}
      end
    end

    result
  end


  def physical_representations_for_top_containers(top_container_ids)
    self.handle_deaccessions_for_ids(PhysicalRepresentation
                                       .find_relationship(:representation_container)
                                       .find_by_participant_ids(TopContainer, top_container_ids)
                                       .map {|relationship| relationship[:physical_representation_id]})
  end


  def assign_for_model_with_type_ids(operation, model, type, *ids)
    # operation is :add or :remove
    # model is the kind of objects we want to add
    # type is the kind of object ids we've been given

    raise OperationNotPermitted.new("Unknown assign operation: #{operation}") unless [:add, :remove].include?(operation)

    # if they are the same then go ahead and add the ids
    if model == type
      if operation == :add
        self.add_objects(model, *ids)
      elsif operation == :remove
        self.remove_objects(model, *ids)
      else
        raise "Unknown assign operation: #{operation}"
      end
    else
      # otherwise we need to recurse down until they are the same
      case type
      when 'resource'
        self.assign_for_model_with_type_ids(operation, model, 'archival_object', *toplevel_aos_for_resources(ids))
      when 'archival_object'
        self.assign_for_model_with_type_ids(operation, model, model, *objects_for_aos(model, ids))
      when 'top_container'
        self.assign_for_model_with_type_ids(operation, model, model, *physical_representations_for_top_containers(ids))
      else
        raise InvalidRef.new("Don't know how to find refs of type: #{type.inspect} for model: #{model.inspect}")
      end

    end
  end


  def assign_by_ref(operation, model, *refs)
    raise OperationNotPermitted.new("Assigning objects not permitted for batches with actions") unless self.status == 'no_action'

    refs.map {|ref| {:ref => ref, :parsed => JSONModel.parse_reference(ref)}}
      .group_by {|parsed|
                  raise InvalidRef.new("Malformed ref: #{parsed[:ref]}") if parsed[:parsed].nil?
                  parsed[:parsed].fetch(:type)}
      .each do |type, type_refs|

      unless Batch.ref_types_for(model).include?(type)
        raise InvalidRef.new("Can't handle refs of type: #{type.inspect} for model: #{model.inspect}")
      end

      ids = type_refs.map {|ref| ref[:parsed].fetch(:id)}

      self.assign_for_model_with_type_ids(operation, model, type, *ids)

    end
  end


  def add_by_ref(model, *refs)
    self.assign_by_ref(:add, model, *refs)
  end


  def remove_by_ref(model, *refs)
    self.assign_by_ref(:remove, model, *refs)
  end


  def objects_ds
    DB.open do |db|
      db[:batch_objects]
        .filter(:batch_id => self.id)
        .select(*Batch.id_columns)
    end
  end


  def object_refs
    objects_ds.map{|row| uri_for_batch_objects_row(row)}
  end


  def object_counts
    objects_ds.group_and_count{Batch.id_columns.map{|col| Sequel.~(col => nil).as(col)}}.map{|row|
      [Batch.id_column_to_model(row.select{|k,v| v > 0}.keys.first), row[:count]]
    }.to_h
  end


  def object_total
    objects_ds.count
  end


  def included_models
    object_counts.keys
  end


  def status
    actions = related_records(:batch_action_batch)

    return 'no_action' if actions.empty?

    current_action_status = BatchAction.filter(:batch_action__id => actions.map{|a| a[:id]})
      .left_join(Sequel.as(:enumeration_value, :status), :status__id => :batch_action__action_status_id)
      .filter(Sequel.~(:status__value => 'executed'))
      .select(:status__value).get(:status__value)

    current_action_status || 'executed'
  end


  def current_action
    BatchAction.sequel_to_jsonmodel(related_records(:batch_action_batch)).select{|action| action['action_status'] != 'executed'}.first
  end


  def delete_current_action
    unless (action = self.current_action)
      raise InvalidAction.new('No current action to delete.')
    end

    BatchAction[action.id].delete
  end


  def add_action(type, params = {})
    if current_action
      raise InvalidAction.new('Cannot add action. Batch already has a current action.')
    end

    unless (self.included_models - BatchActionHandler.models_for_type(type)).empty?
      raise InvalidAction.new('Cannot add action. Batch has unsupported models.')
    end

    handler = BatchActionHandler.handler_for_type(type)

    params = handler.default_params if params.empty?
    handler.validate_params(params)

    json = {
      :action_type => type.to_s,
      :action_params => params.to_json,
      :action_status => 'draft',
      :action_user => RequestContext.get(:current_username),
      :batch => {:ref => self.uri}
    }

    BatchAction.create_from_json(JSONModel(:batch_action).from_hash(json))
  end


  def update_action_status(status)
    action = self.current_action

    unless action
      raise InvalidAction.new('Batch does not have a current action')
    end

    if status == 'approved'
      if BatchActionHandler.action_requires_approval?(action['action_type'])
        approval_perm = BatchActionHandler.approval_for_type(action['action_type'])
        current_user = User[:username => RequestContext.get(:current_username)]
        unless current_user.can?(approval_perm)
          raise OperationNotPermitted.new("User does not have pwermission to approve this action.")
        end
      end

      action['approved_user'] = RequestContext.get(:current_username)
      action['approved_time'] = Time.now
    end

    action['action_status'] = status

    BatchAction.get_or_die(JSONModel.parse_reference(action['uri'])[:id]).update_from_json(action)
  end


  def perform_action
    action = current_action

    unless action
      raise InvalidAction.new('Batch does not have a current action to perform.')
    end

    if BatchActionHandler.action_requires_approval?(action['action_type'])
      unless action['action_status'] == 'approved'
        raise OperationNotPermitted.new("Action nust be approved before it can be performed.")
      end
    end

    handler = BatchActionHandler.handler_for_type(action['action_type'])

    handler.perform_action(ASUtils.json_parse(action['action_params']), action['action_user'], action['uri'], self.object_refs)

    action['action_status'] = 'executed'
    action['action_time'] = Time.now
    BatchAction.get_or_die(JSONModel.parse_reference(action['uri'])[:id]).update_from_json(action)
  end


  def uri_for_batch_objects_row(row)
    col = Batch.column_for_row(row)
    id = row[col]

    JSONModel(Batch.id_column_to_model(col)).uri_for(id, :repo_id => RequestContext.get(:repo_id))
  end


  def update_from_json(json, opts = {}, apply_nested_records = true)
    if json.has_key?('current_action')
      current_action = self.current_action
      if current_action
        ca_json = json['current_action']

        current_action['action_params'] = ca_json['action_params']
        current_action['note'] = ca_json['note']
        current_action['lock_version'] = ca_json['lock_version']

        BatchAction.get_or_die(JSONModel.parse_reference(current_action['uri'])[:id]).update_from_json(current_action)

        # the update to the BatchAction causes a bump to the Batch's lock_version, so bump here to catch up
        json['lock_version'] = json['lock_version'].to_i + 1
      end
      json['current_action'] = nil
    end

    super
  end


  def self.sequel_to_jsonmodel(objs, opts = {})
    jsons = super

    objs.zip(jsons).each do |obj, json|
      json['status'] = obj.status
      objects = obj.object_total
      json['object_count'] = objects
      json['model_counts'] = obj.object_counts
      actions = json['actions'].length
      json['current_action'] = obj.current_action
      json['display_string'] = "#{obj.qsa_id_prefixed}: #{objects} object#{objects == 1 ? '' : 's'} -- #{actions} action#{actions == 1 ? '' : 's'}"
    end

    jsons
  end


  def self.handle_delete(ids_to_delete)
    DB.open do |db|
      db[:batch_objects].filter(:batch_id => ids_to_delete).delete
    end

    super
  end
end
