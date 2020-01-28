class ContainerProfiler < BatchActionHandler

  register(:container_profiler,
           'Update container profile.',
           [:top_container])


  def self.default_params
    {
      'container_profile' => nil
    }
  end


  def self.validate_params(params)
    params['container_profile'] or raise InvalidParams.new('Must provide a container profile')
  end


  def self.perform_action(params, user, action_uri, uris)
    validate_params(params)

    cp_ref = JSONModel.parse_reference(params['container_profile']['ref'])

    username = RequestContext.get(:current_username)
    user_agent_id = User[:username => username][:agent_record_id]

    now = Time.now

    rlshp_row = {
      :top_container_id => 'SETME',
      :container_profile_id => cp_ref[:id],
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

        db[:top_container_profile_rlshp].filter(:top_container_id => ref[:id]).delete
        rlshp_row[:top_container_id] = ref[:id]
        db[:top_container_profile_rlshp].insert(rlshp_row)

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

    cp_title = ASUtils.json_parse(params['container_profile']['_resolved'])['title']

    "#{count} top container#{count == 1 ? '' : 's'} linked to #{cp_title}."
  end
end
