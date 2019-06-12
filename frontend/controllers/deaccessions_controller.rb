class DeaccessionsController < ApplicationController

  set_access_control "view_repository" => [:affected_records]

  def affected_records
    records = JSONModel::HTTP.get_json("/repositories/#{session[:repo_id]}/deaccessions/affected_records", {uri: params[:uri]})
    render_aspace_partial :partial => 'shared/deaccession_affected_records', :locals => {:records => records}
  end

end