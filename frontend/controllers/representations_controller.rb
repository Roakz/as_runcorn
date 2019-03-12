class RepresentationsController < ApplicationController

  set_access_control "view_repository" => [:index]

  REPRESENTATION_FACETS = ['primary_type', 'representation_intended_use_u_sstr'] + Plugins.search_facets_for_type(:digital_representation) + Plugins.search_facets_for_type(:physical_representation)

  def index
    respond_to do |format|
      format.html {
        @search_data = Search.for_type(session[:repo_id], ['physical_representation', 'digital_representation'], params_for_backend_search.merge({"facet[]" => REPRESENTATION_FACETS}))
      }
      format.csv {
        search_params = params_for_backend_search.merge({"facet[]" => REPRESENTATION_FACETS})
        search_params["type[]"] = ['physical_representation', 'digital_representation']
        uri = "/repositories/#{session[:repo_id]}/search"
        csv_response( uri, search_params )
      }
    end
  end

end
