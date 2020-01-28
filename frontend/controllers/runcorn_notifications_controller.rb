class RuncornNotificationsController < ApplicationController

  set_access_control "view_repository" => [:list]

  def list
    notifications = JSONModel::HTTP.get_json("/repositories/#{session[:repo_id]}/runcorn_notifications")
    render_aspace_partial :partial => 'notifications/list', :locals => {:notifications => notifications}
  end
end