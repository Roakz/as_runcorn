class ItemUsesController < ApplicationController

  set_access_control  "view_repository" => [:index, :show]

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
                                       }.merge(item_use_search_params(params_for_backend_search)))
      }
      format.csv {
        search_params = item_use_search_params(params_for_backend_search)
        search_params["facet[]"] = ITEM_USE_FACETS
        search_params["type[]"] = "item_use"
        search_params["sort"] = "user_mtime desc"
        uri = "/repositories/#{session[:repo_id]}/item_uses/csv"

        Search.build_filters(search_params)
        csv_response(uri, search_params, 'item_uses_')
      }
    end
  end

  def show
    item_use = JSONModel(:item_use).find(params[:id])
    redirect_to :controller => :resolver, :action => :resolve_readonly, :uri => item_use.representation['ref']
  end


  def item_use_search_params(search_params)
    if params['date_range_start'] || params['date_range_end']
      date_query = {
        'query' => {
          'jsonmodel_type' => 'range_query',
          'field' => 'item_use_start_date_u_ssort',
          'from' => params[:date_range_start],
          'to' => params[:date_range_end],
        }
      }

      search_params['filter'] = JSONModel(:advanced_query).from_hash(date_query).to_json
    end

    search_params
  end

end
