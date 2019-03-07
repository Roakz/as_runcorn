class ArchivesSpaceService < Sinatra::Base

  Endpoint.get('/repositories/:repo_id/physical_representations')
    .description("List all physical representations for indexing")
    .params(["repo_id", :repo_id])
    .paginated(true)
    .permissions([:index_system])
    .returns([200, '[:physical_representation]']) \
  do
    handle_listing(PhysicalRepresentation, params)
  end

  Endpoint.get('/repositories/:repo_id/physical_representations/backlink_uri/:physical_representation_id')
    .description("Get a ref for the record containing a given physical representation")
    .params(["repo_id", :repo_id],
            ["physical_representation_id", Integer, "The requested ID"])
    .permissions([:view_repository])
    .returns([200, '{"ref": <id>}']) \
  do
    json_response({'ref' => PhysicalRepresentation.ref_for(params[:physical_representation_id])})
  end

end
