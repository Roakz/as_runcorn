class ConservationRequestsController < ApplicationController

  RESOLVES = []

  # FIXME: Who should be able to create/edit conservation requests?  Assuming
  # any logged in user here.
  set_access_control "view_repository" => [:new, :edit, :create, :update,
                                           :index, :show, :linked_representations,
                                           :assign_records_form, :assign_records,
                                           :clear_assigned_records,
                                           :spawn_assessment]

  def index
    @search_data = Search.for_type(
      session[:repo_id],
      "conservation_request",
      {
        "sort" => "title_sort asc",
        "facet[]" => Plugins.search_facets_for_type(:conservation_request) + [
          'conservation_request_status_u_sstr',
          'conservation_request_reason_requested_u_sstr',
        ],
      }.merge(params_for_backend_search)
    )
  end

  def new
    @conservation_request = JSONModel(:conservation_request).new._always_valid!
  end

  def show
    @conservation_request = JSONModel(:conservation_request).find(params[:id], find_opts)
  end

  def assign_records_form
    @conservation_request = JSONModel(:conservation_request).find(params[:id], find_opts)
  end

  def assign_records
    JSONModel::HTTP.post_form("/repositories/#{session[:repo_id]}/conservation_requests/#{params[:id]}/assign_records",
                              'adds[]' => Array(params.dig(:conservation_request_adds, 'ref')),
                              'removes[]' => Array(params.dig(:conservation_request_removes, 'ref')))

    return redirect_to :controller => :conservation_requests, :action => :show
  end

  def edit
    show
  end

  def create
    handle_crud(:instance => :conservation_request,
                :model => JSONModel(:conservation_request),
                :on_invalid => ->(){
                  return render :action => :new
                },
                :on_valid => ->(id){
                  flash[:success] = I18n.t("conservation_request._frontend.messages.created")
                  return redirect_to :controller => :conservation_requests, :action => :new if params.has_key?(:plus_one)
                  redirect_to :controller => :conservation_requests, :action => :show, :id => id
                })
  end

  def update
    handle_crud(:instance => :conservation_request,
                :model => JSONModel(:conservation_request),
                :obj => JSONModel(:conservation_request).find(params[:id]),
                :on_invalid => ->(){ return render :action => :edit },
                :on_valid => ->(id){
                  flash[:success] = I18n.t("conservation_request._frontend.messages.updated")
                  redirect_to :controller => :conservation_requests, :action => :show, :id => id
                })
  end


  def delete
    conservation_request = JSONModel(:conservation_request).find(params[:id])
    conservation_request.delete

    flash[:success] = I18n.t("conservation_request._frontend.messages.deleted", JSONModelI18nWrapper.new(:conservation_request => conservation_request))
    redirect_to(:controller => :conservation_requests, :action => :index, :deleted_uri => conservation_request.uri)
  end

  def spawn_assessment
    conservation_request = JSONModel(:conservation_request).find(params[:id])
    redirect_to(:controller => :assessments, :action => :new, :conservation_request_uri => conservation_request.uri)
  end

  def linked_representations
    respond_to do |format|
      format.js {
        raise "Not supported" unless params[:listing_only]

        criteria = params_for_backend_search

        response = JSONModel::HTTP.post_form("/repositories/#{session[:repo_id]}/conservation_requests/#{params[:id]}/search_assigned_records",
                                             criteria)

        @search_data = SearchResultData.new(ASUtils.json_parse(response.body).merge(:criteria => criteria))

        render_aspace_partial(:partial => "conservation_requests/linked_representations_listing",
                              locals: {
                                filter_property: params[:filter_property],
                                filter_value: params[:filter_value]
                              })
      }
    end
  end

  def clear_assigned_records
    JSONModel::HTTP.post_form("/repositories/#{session[:repo_id]}/conservation_requests/#{params[:id]}/clear_assigned_records")

    redirect_to(:controller => :conservation_requests, :action => :assign_records_form)
  end


  def current_record
    @conservation_request
  end

end
