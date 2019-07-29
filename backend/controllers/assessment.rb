class ArchivesSpaceService < Sinatra::Base
  Endpoint.post('/repositories/:repo_id/assessments/:id/search_assigned_records')
    .description("Search within assigned records")
    .params(["repo_id", :repo_id],
            ["id", :id],
            *ArchivesSpaceService::BASE_SEARCH_PARAMS)
    .paginated(true)
    .permissions([])
    .returns([200, :updated]) \
  do
    # See the corresponding `search` method in conservation_request.rb for an
    # explanation of what's going on here.
    query = "{!terms f=id}"

    assessment = Assessment.get_or_die(params[:id])
    assessment.connected_record_refs.each_with_index do |uri, idx|
      query << ',' if idx > 0
      query << uri
    end

    params[:q] = query

    json_response(Search.search(params, params[:repo_id]))
  end
end
