class ArchivesSpaceService < Sinatra::Base

  Endpoint.get('/repositories/:repo_id/runcorn_notifications')
      .description("List all notifications for the current user")
      .params(["from_date", String, "From date", :optional => true],
              ["repo_id", :repo_id])
      .permissions([:view_repository])
      .returns([200, "(:json)"]) \
  do
    json_response(RuncornNotifications.new(params[:from_date]))
  end

end