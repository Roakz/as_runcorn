class ArchivesSpaceService < Sinatra::Base

  # a new endpoint for bulk updating the function locations for a batch
  Endpoint.post('/repositories/:repo_id/top_containers/batch/functional_location')
    .description("Update the functional location for a batch of top containers")
    .params(["ids", [Integer]],
            ["location", String, "The enum value of the location"],
            ["repo_id", :repo_id])
    .permissions([:manage_container_record])
    .returns([200, :updated]) \
  do
    user_uri = User.uri_for(current_user.agent_record_type, current_user.agent_record_id)
    result = TopContainer.bulk_update_location(params[:ids], params[:location], user_uri)
    json_response(result)
  end

end
