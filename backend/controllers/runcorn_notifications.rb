class ArchivesSpaceService < Sinatra::Base

  Endpoint.get('/repositories/:repo_id/runcorn_notifications')
      .description("List all notifications for the current user")
      .params(["repo_id", :repo_id])
      .permissions([:view_repository])
      .returns([200, "(:json)"]) \
  do
    json_response(RuncornNotifications.new)
  end

end