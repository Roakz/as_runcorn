class ArchivesSpaceService < Sinatra::Base

  Endpoint.get('/repositories/:repo_id/digital_representations')
    .description("List all digital representations for indexing")
    .params(["repo_id", :repo_id])
    .paginated(true)
    .permissions([:index_system])
    .returns([200, '[:digital_representation]']) \
  do
    handle_listing(DigitalRepresentation, params)
  end

  Endpoint.get('/repositories/:repo_id/digital_representations/backlink_uri/:digital_representation_id')
    .description("Get a ref for the record containing a given digital representation")
    .params(["repo_id", :repo_id],
            ["digital_representation_id", Integer, "The requested ID"])
    .permissions([:view_repository])
    .returns([200, '{"ref": <id>}']) \
  do
    json_response({'ref' => DigitalRepresentation.ref_for(params[:digital_representation_id])})
  end

end
