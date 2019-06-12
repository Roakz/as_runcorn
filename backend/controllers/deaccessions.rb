class ArchivesSpaceService < Sinatra::Base
  Endpoint.get('/repositories/:repo_id/deaccessions/affected_records')
    .description("Get a list of Chargeable Items")
    .params(["repo_id", :repo_id],
            ["uri", String, "URI of record to check"])
    .permissions([:view_repository])
    .returns([200, "[(JSON list of record titles)]"]) \
  do
    json_response(DeaccessionHelper.affected_records(params[:uri]))
  end
end
