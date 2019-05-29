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

  Endpoint.post("/repositories/:repo_id/digital_representations/upload_file")
    .description("Upload a digital representation file")
    .params(["file", UploadFile, "The file stream"])
    .permissions([])
    .returns([200, '{"key": "<opaque key>"}']) \
  do
    # FIXME: We should store these in S3
    key = RepresentationFileStore.new.store_file(params[:file])

    json_response({"key" => key})
  end

  Endpoint.get("/repositories/:repo_id/digital_representations/view_file")
    .description("Fetch a digital representation file")
    .params(["key", String, "The key returned by a previous call to upload_file"])
    .permissions([])
    .returns([200, 'application/octet-stream']) \
  do
    send_file RepresentationFileStore.new.get_file(params[:key])
  end

end
