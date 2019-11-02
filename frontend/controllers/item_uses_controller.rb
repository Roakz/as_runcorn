class ItemUsesController < ApplicationController

  set_access_control  "view_repository" => [:index]

  ITEM_USE_FACETS = [
                     'item_use_status_u_ssort',
                     'item_use_type_u_ssort',
                    ]

  def index
    respond_to do |format|
      format.html {
        @search_data = Search.for_type(session[:repo_id], "item_use", params_for_backend_search.merge({"facet[]" => ITEM_USE_FACETS}))
      }
      format.csv {
        search_params = params_for_backend_search.merge({"facet[]" => ITEM_USE_FACETS})
        search_params["type[]"] = "item_use"
        uri = "/repositories/#{session[:repo_id]}/search"
        csv_response( uri, search_params )
      }
    end
  end
end
