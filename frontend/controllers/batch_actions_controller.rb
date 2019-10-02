class BatchActionsController < ApplicationController

  set_access_control "view_repository" => [:show]


  def show
    batch_action_id = Integer(params[:id])

    record_uri = JSONModel::HTTP.get_json("/repositories/#{session[:repo_id]}/batch_actions/backlink_uri/#{batch_action_id}").fetch('ref')

    resolver = Resolver.new(record_uri)

    # FIXME: jump to the right subrecord section
    redirect_to resolver.view_uri
  end

end
