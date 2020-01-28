class RuncornNotificationsController < ApplicationController

  set_access_control "view_repository" => [:list]

  def list
    # Show notifications within the last 7 day window
    from_date = (Date.today - 7).iso8601
    notifications = JSONModel::HTTP.get_json("/repositories/#{session[:repo_id]}/runcorn_notifications", {:from_date => from_date})
    render_aspace_partial :partial => 'notifications/list', :locals => {:notifications => notifications}
  end
end