class ArchivesSpaceService < Sinatra::Base

  Endpoint.get('/repositories/:repo_id/conservation_requests')
    .description("List all conservation requests for indexing")
    .params(["repo_id", :repo_id])
    .paginated(true)
    .permissions([:index_system])
    .returns([200, '[:conservation_request]']) \
  do
    handle_listing(ConservationRequest, params)
  end

  Endpoint.post('/repositories/:repo_id/conservation_requests')
    .description("Create a Conservation Request")
    .params(["repo_id", :repo_id],
            ["conservation_request", JSONModel(:conservation_request), "The updated record", :body => true])
    .permissions([])
    .returns([200, :created]) \
  do
    handle_create(ConservationRequest, params[:conservation_request])
  end

  Endpoint.post('/repositories/:repo_id/conservation_requests/:id')
    .description("Update a Conservation Request")
    .params(["repo_id", :repo_id],
            ["id", :id],
            ["conservation_request", JSONModel(:conservation_request), "The updated record", :body => true])
    .permissions([])
    .returns([200, :updated]) \
  do
    handle_update(ConservationRequest, params[:id], params[:conservation_request])
  end

  Endpoint.delete('/repositories/:repo_id/conservation_requests/:id')
    .description("Delete a Conservation Request")
    .params(["repo_id", :repo_id],
            ["id", :id])
    .permissions([])
    .returns([200, :deleted]) \
  do
    handle_delete(ConservationRequest, params[:id])
  end

  Endpoint.get('/repositories/:repo_id/conservation_requests/:id')
    .description("Get a Conservation Request by ID")
    .params(["repo_id", :repo_id],
            ["id", :id],
            ["resolve", :resolve])
    .permissions([])
    .returns([200, "(:conservation_request)"]) \
  do

    json = ConservationRequest.to_jsonmodel(params[:id])
    json_response(resolve_references(json, params[:resolve]))
  end

  Endpoint.post('/repositories/:repo_id/conservation_requests/:id/assign_records')
    .description("Add and remove records from a conservation request")
    .params(["repo_id", :repo_id],
            ["adds", [String], "List of references to add", :optional => true],
            ["removes", [String], "List of references to remove", :optional => true],
            ["id", :id])
    .permissions([])
    .returns([200, :updated]) \
  do
    conservation_request = ConservationRequest.get_or_die(params[:id])

    conservation_request.add_by_ref(*Array(params[:adds]))
    conservation_request.remove_by_ref(*Array(params[:removes]))

    json_response("status" => "OK")
  end

end
