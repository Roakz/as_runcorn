class QsaIdController < ApplicationController

  set_access_control "view_repository" => [:show]

  def show
    qsa_id = params[:qsa_id]
    record_uri = JSONModel::HTTP.get_json("/repositories/#{session[:repo_id]}/qsa_id/resolve/#{qsa_id}").fetch('ref')
    resolver = Resolver.new(record_uri)

    redirect_to resolver.view_uri
  end

end
