module MovementsHelper

  # The movement.user linker needs to default to the current user
  # it links via the user's agent record uri, which, sadly, we don't have
  # so let's get it, and stash it since it won't be changing much
  # FIXME: feels like there's a better way to do this
  def self.agent_for_user(user_uri)
    return @agent_for_user_hash if user_uri == @agent_for_user_uri

    @agent_for_user_uri = user_uri
    json = JSONModel::HTTP.get_json(user_uri)
    @agent_for_user_hash = {'uri' => json['agent_record']['ref'], 'display_string' => json['name']}
  end
end
