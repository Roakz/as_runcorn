class ArchivesSpaceService < Sinatra::Base

  Endpoint.get('/repositories/:repo_id/qsa_id/resolve/:qsa_id')
    .description("Get a ref for a qsa_id")
    .params(["repo_id", :repo_id],
            ["qsa_id", String, "The QSA Id"])
    .permissions([:view_repository])
    .returns([200, '{"ref": <id>}']) \
  do
    json_response({'ref' => QSAId.ref_for(params[:qsa_id], params[:repo_id])})
  end

end
