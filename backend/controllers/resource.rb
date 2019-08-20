class ArchivesSpaceService < Sinatra::Base

  Endpoint.get('/repositories/:repo_id/resources/:id/gaps_in_control')
    .description("Get a Gaps in Control for a resource hierarchy")
    .params(["id", :id],
            ["repo_id", :repo_id])
    .permissions([:view_repository])
    .returns([200, "(:json array of objects)"]) \
  do
    resource = Resource.get_or_die(params[:id])
    json_response(resource.calculate_gaps_in_control!)
  end

end