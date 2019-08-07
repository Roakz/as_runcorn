class ArchivesSpaceService < Sinatra::Base
  Endpoint.get('/repositories/:repo_id/significant_items/:level')
    .description("Get significant item lists")
    .params(["repo_id", :repo_id],
            ["level", String, "Significance level (or 'all')"],
            ["series", [String], "URIs of series", :optional => true])
    .permissions([])
    .returns([200, '[:physical_representation]'],
             [400, :error]) \
  do
    levels = BackendEnumSource.values_for('runcorn_significance').reject{|sig| sig == 'standard'}.push('all')
    if levels.include?(params[:level])
      json_response(SignificantItems.list(params))
    else
      json_response({:error => "Unknown significance level: #{params[:level]}. Supported levels: #{levels.join(' ')}"}, 400)
    end
  end
end
