class FunctionalMove < BatchActionHandler

  register(:functional_move,
           'Create a movement to a new functional location.',
           [:top_container, :physical_representation])


  def self.default_params
    {
      'location' => 'HOME'
    }
  end


  def self.validate_params(params)
    location = params['location'] or raise InvalidParams.new('Must provide a location')

    locs = BackendEnumSource.values_for('runcorn_location')
    unless locs.include?(location)
      raise InvalidParams.new('location must be one of: ' + locs.join(', '))
    end
  end


  def self.perform_action(params, user, action_uri, uris)
    validate_params(params)

    username = RequestContext.get(:current_username)
    user_agent_id = User[:username => username][:agent_record_id]
    location_id = BackendEnumSource.id_for_value('runcorn_location', params['location'])

    now = Time.now

    movement_row = {
      :top_container_id => 'SETME',
      :physical_representation_id => 'SETME',
      :storage_location_id => nil,
      :functional_location_id => location_id,
      :context_uri => action_uri,
      :move_date => Date.today.strftime('%Y-%m-%d'),
      :json_schema_version => 1,
      :lock_version => 0,
      :created_by => username,
      :last_modified_by => username,
      :create_time => now,
      :system_mtime => now,
      :user_mtime => now,
    }

    movement_user_rlshp_row = {
      :movement_id => 'SETME',
      :agent_person_id => user_agent_id,
      :aspace_relationship_position => 0,
      :created_by => username,
      :last_modified_by => username,
      :system_mtime => now,
      :user_mtime => now,
    }

    models = ASModel.all_models.select {|model| model.included_modules.include?(Movements)}

    count = 0

    ids = {:top_container => [], :physical_representation => []}

    DB.open do |db|
      uris.each do |uri|
        ref = JSONModel.parse_reference(uri)

        if ref[:type] == 'top_container'
          ids[:top_container].push(ref[:id])
          movement_row[:top_container_id] = ref[:id]
          movement_row[:physical_representation_id] = nil
        elsif ref[:type] == 'physical_representation'
          ids[:physical_representation].push(ref[:id])
          movement_row[:top_container_id] = nil
          movement_row[:physical_representation_id] = ref[:id]
        else
          raise InvalidParams.new('Unknown uri type: ' + ref[:type])
        end

        movement_id = db[:movement].insert(movement_row)

        movement_user_rlshp_row[:movement_id] = movement_id
        db[:movement_user_rlshp].insert(movement_user_rlshp_row)

        count += 1
      end

      # update location of affected records and touch for indexing
      ids.each do |model, id_list|
        unless id_list.empty?
          db[model].filter(:id => id_list)
            .update(:current_location_id => location_id, :lock_version => Sequel.expr(1) + :lock_version, :system_mtime => now)
        end
      end

      # bump lock_version for affected AOs for history
      linked_ao_ids = db[:physical_representation].filter(:id => ids[:physical_representation]).select(:archival_object_id)
      ArchivalObject.filter(:id => linked_ao_ids).update(:lock_version => Sequel.expr(1) + :lock_version, :system_mtime => now)
    end

    "#{count} object#{count == 1 ? '' : 's'} moved to #{I18n.t('enumerations.runcorn_location.' + params['location'])}."
  end
end
