class ItemUsesController < ApplicationController

  set_access_control  "view_repository" => [:index]

  include ExportHelper

  ITEM_USE_FACETS = [
                     'item_use_status_u_ssort',
                     'item_use_type_u_ssort',
                    ]

  def index
    respond_to do |format|
      format.html {
        @search_data = Search.for_type(session[:repo_id],
                                       "item_use",
                                       {
                                         "facet[]" => ITEM_USE_FACETS,
                                         "sort" => "user_mtime desc"
                                       }.merge(params_for_backend_search))
      }
      format.csv {
        search_params = params_for_backend_search
        search_params["facet[]"] = ITEM_USE_FACETS
        search_params["type[]"] = "item_use"
        search_params["sort"] = "user_mtime desc"
        uri = "/repositories/#{session[:repo_id]}/search"
#        uri = "/repositories/#{session[:repo_id]}/item_uses/csv"

        Search.build_filters(search_params)
        csv_response( uri, search_params )
      }
    end
  end
end
