class HomeMove < BatchActionHandler

  register(:home_move,
           'Create a movement to a new home location.',
           [:top_container])


  def self.default_params
    {
      'location' => nil
    }
  end


  def self.validate_params(params)
    params['location'] or raise InvalidParams.new('Must provide a location')
  end


  def self.perform_action(params, user, action_uri, uris)
    validate_params(params)

    loc_ref = JSONModel.parse_reference(params['location']['ref'])

    username = RequestContext.get(:current_username)
    user_agent_id = User[:username => username][:agent_record_id]

    now = Time.now

    movement_row = {
      :top_container_id => 'SETME',
      :storage_location_id => 'SETME',
      :functional_location_id => nil,
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

    housed_at_row = {
      :top_container_id => 'SETME',
      :location_id => 'SETME',
      :aspace_relationship_position => 0,
      :created_by => username,
      :last_modified_by => username,
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

    count = 0

    ids = {:top_container => []}

    DB.open do |db|
      uris.each do |uri|
        ref = JSONModel.parse_reference(uri)

        ids[:top_container].push(ref[:id])
        movement_row[:top_container_id] = ref[:id]
        movement_row[:storage_location_id] = loc_ref[:id]

        movement_id = db[:movement].insert(movement_row)

        movement_user_rlshp_row[:movement_id] = movement_id
        db[:movement_user_rlshp].insert(movement_user_rlshp_row)

        db[:top_container_housed_at_rlshp].filter(:top_container_id => ref[:id]).delete
        housed_at_row[:top_container_id] = ref[:id]
        housed_at_row[:location_id] = loc_ref[:id]
        db[:top_container_housed_at_rlshp].insert(housed_at_row)

        count += 1
      end

      # touch affected records for indexing
      ids.each do |model, id_list|
        unless id_list.empty?
          db[model].filter(:id => id_list)
            .update(:lock_version => Sequel.expr(1) + :lock_version, :system_mtime => now)
        end
      end
    end

    loc_title = ASUtils.json_parse(params['location']['_resolved'])['title']

    "#{count} top container#{count == 1 ? '' : 's'} moved to #{loc_title}."
  end
end
