class TopContainer
  prepend RepresentationContainers
  include Movements
  move_to_storage_permitted
  include ContentsAwareness

  # replacements for:
  #   self.bulk_update_location(ids, location_uri)
  #   self.bulk_update_locations(location_data)
  # movements require a user uri so adding it to the sigs
  # the endpoints now call these versions

  # also changed location_uri to location here
  # the move method can take a uri (for a storage location)
  # or an enum value (for a functional location)
  def self.bulk_update_location(ids, location, user_uri = nil)
    if user_uri.nil?
      current_user = User[:username => RequestContext.get(:current_username)]
      user_uri = User.uri_for(current_user.agent_record_type, current_user.agent_record_id)
    end

    out = {:records_updated => ids.length}

    opts = {
      :user => user_uri,
      :location => location
    }

    begin
      ids.each do |id|
        TopContainer[id].move(opts)
      end
    rescue
      Log.exception($!)

      out[:records_updated] = 0
      out[:error] = $!
    end

    out
  end


  def self.bulk_update_locations(location_data, user_uri = nil)
    if user_uri.nil?
      current_user = User[:username => RequestContext.get(:current_username)]
      user_uri = User.uri_for(current_user.agent_record_type, current_user.agent_record_id)
    end


    out = {
      :records_ids_updated => []
    }

    opts = {
      :user => user_uri
    }

    ids = location_data.map{|uri,_| my_jsonmodel.id_for(uri)}

    location_data.each do |uri, location_uri|
      id = my_jsonmodel.id_for(uri)
      
      begin
        TopContainer[id].move(opts.merge(:location => location_uri))

        out[:records_ids_updated] << id
      rescue
        Log.exception($!)

        out[:error] = $!
      end
    end

    out[:records_updated] = out[:records_ids_updated].length

    out
  end
end
