class SignificantItemsController < ApplicationController

  set_access_control "view_repository" => [:index]

  def index
    @significant_items = JSONModel::HTTP.get_json("/repositories/#{session[:repo_id]}/significant_items/all", 'series[]' => [params[:series_uri]])
  end

end
