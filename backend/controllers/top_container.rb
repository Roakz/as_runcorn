class ArchivesSpaceService < Sinatra::Base

  # overriding bulk movement endpoints to include user which is required for movements
  Endpoint.post('/repositories/:repo_id/top_containers/batch/location')
    .description("Update location for a batch of top containers")
    .params(["ids", [Integer]],
            ["location_uri", String, "The uri of the location"],
            ["repo_id", :repo_id])
    .permissions([:manage_container_record])
    .returns([200, :updated]) \
  do
    user_uri = User.uri_for(current_user.agent_record_type, current_user.agent_record_id)
    result = TopContainer.bulk_update_location(params[:ids], params[:location_uri], user_uri)
    json_response(result)
  end


  Endpoint.post('/repositories/:repo_id/top_containers/bulk/locations')
  .description("Bulk update locations")
    .params(["location_data", String, "JSON string containing location data {container_uri=>location_uri}", :body => true],
          ["repo_id", :repo_id])
  .permissions([:manage_container_record])
  .returns([200, :updated]) \
  do
    user_uri = User.uri_for(current_user.agent_record_type, current_user.agent_record_id)
    begin
      result = TopContainer.bulk_update_locations(ASUtils.json_parse(params[:location_data]), user_uri)
      json_response(result)
    rescue Sequel::ValidationFailed => e
      json_response({:error => e.errors, :uri => e.model.uri}, 400)
    end
  end
end
