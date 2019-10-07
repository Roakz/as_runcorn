class BatchesController < ApplicationController

  RESOLVES = ['actions']

  # FIXME: Who should be able to create/edit batches?  Assuming
  # any logged in user here.
  set_access_control "view_repository" => [:new, :edit, :create, :update, :delete,
                                           :create_from_search,
                                           :index, :show, :assigned_objects,
                                           :assign_objects_form, :assign_objects,
                                           :clear_assigned_objects,
                                           :add_action_form, :add_action,
                                           :submit_for_review, :approve,
                                           :revert_to_draft, :delete_action,
                                           :dry_run, :perform_action,
                                           :csv]

  helper_method :batch_action_types
  def batch_action_types
    @supported_models ||= MemoryLeak::Resources.get(:batch_action_types)
  end

  helper_method :batch_action_type
  def batch_action_type(type)
    batch_action_types.select{|t| t['type'] == type}.first
  end

  def index
    @search_data = Search.for_type(
      session[:repo_id],
      "batch",
      {
        "sort" => "title_sort asc",
        "facet[]" => Plugins.search_facets_for_type(:batch),
      }.merge(params_for_backend_search)
    )
  end

  def new
    @batch = JSONModel(:batch).new._always_valid!
  end

  def show
    @batch = JSONModel(:batch).find(params[:id], find_opts.merge('resolve[]' => RESOLVES))
  end

  def assign_objects_form
    @batch = JSONModel(:batch).find(params[:id], find_opts.merge('resolve[]' => RESOLVES))
  end

  def assign_objects
    JSONModel::HTTP.post_form("/repositories/#{session[:repo_id]}/batches/#{params[:id]}/assign_objects",
                              'model' => params[:model],
                              'adds[]' => Array(params.dig(:batch_adds, 'ref')),
                              'removes[]' => Array(params.dig(:batch_removes, 'ref')),
                              'include_deaccessioned' => params[:include_deaccessioned])

    flash[:success] = I18n.t("batch._frontend.messages.objects_assigned")
    return redirect_to :controller => :batches, :action => :show
  end

  def add_action_form
    @batch = JSONModel(:batch).find(params[:id], find_opts.merge('resolve[]' => RESOLVES))
  end

  def add_action
    JSONModel::HTTP.post_form("/repositories/#{session[:repo_id]}/batches/#{params[:id]}/add_action/#{params[:action_type]}")

    flash[:success] = I18n.t("batch._frontend.messages.action_added")
    return redirect_to :controller => :batches, :action => :show
  end

  def submit_for_review
    JSONModel::HTTP.post_form("/repositories/#{session[:repo_id]}/batches/#{params[:id]}/propose")

    flash[:success] = I18n.t("batch._frontend.messages.submitted_for_review")
    return redirect_to :controller => :batches, :action => :show
  end

  def revert_to_draft
    JSONModel::HTTP.post_form("/repositories/#{session[:repo_id]}/batches/#{params[:id]}/revert_to_draft")

    flash[:success] = I18n.t("batch._frontend.messages.reverted_to_draft")
    return redirect_to :controller => :batches, :action => :show
  end

  def approve
    JSONModel::HTTP.post_form("/repositories/#{session[:repo_id]}/batches/#{params[:id]}/approve")

    flash[:success] = I18n.t("batch._frontend.messages.approved")
    return redirect_to :controller => :batches, :action => :show
  end

  def delete_action
    JSONModel::HTTP.post_form("/repositories/#{session[:repo_id]}/batches/#{params[:id]}/delete_action")

    flash[:success] = I18n.t("batch._frontend.messages.action_deleted")
    return redirect_to :controller => :batches, :action => :show
  end

  def dry_run
    JSONModel::HTTP.post_form("/repositories/#{session[:repo_id]}/batches/#{params[:id]}/dry_run")

    flash[:success] = I18n.t("batch._frontend.messages.dry_run_performed")
    return redirect_to :controller => :batches, :action => :show
  end

  def perform_action
    JSONModel::HTTP.post_form("/repositories/#{session[:repo_id]}/batches/#{params[:id]}/perform_action")

    flash[:success] = I18n.t("batch._frontend.messages.action_performed")
    return redirect_to :controller => :batches, :action => :show
  end

  def edit
    show
  end

  def create
    handle_crud(:instance => :batch,
                :model => JSONModel(:batch),
                :on_invalid => ->(){
                  return render :action => :new
                },
                :on_valid => ->(id){
                  flash[:success] = I18n.t("batch._frontend.messages.created")
                  return redirect_to :controller => :batches, :action => :new if params.has_key?(:plus_one)
                  redirect_to :controller => :batches, :action => :show, :id => id
                })
  end

  def update
    obj = JSONModel(:batch).find(params[:id])

    batch = params[:batch].to_hash
    if (cap = batch['current_action']['action_params'])
      batch['current_action']['action_params'] = ASUtils.to_json(cap)
      params[:batch] = batch
    end

    handle_crud(:instance => :batch,
                :model => JSONModel(:batch),
                :obj => obj,
                :on_invalid => ->(){ return render :action => :edit },
                :on_valid => ->(id){
                  flash[:success] = I18n.t("batch._frontend.messages.updated")
                  redirect_to :controller => :batches, :action => :show, :id => id
                })
  end


  def delete
    batch = JSONModel(:batch).find(params[:id])
    batch.delete

    flash[:success] = I18n.t("batch._frontend.messages.deleted", JSONModelI18nWrapper.new(:batch => batch))
    redirect_to(:controller => :batches, :action => :index, :deleted_uri => batch.uri)
  end


  def create_from_search
    post_uri = URI("/repositories/#{session[:repo_id]}/batches/create_from_search")
    criteria = params_for_backend_search
    Search.build_filters(criteria)
    response = JSONModel::HTTP.post_form(post_uri, criteria)
    result = ASUtils.json_parse(response.body)

    flash[:success] = I18n.t("batch._frontend.messages.created")
    redirect_to :controller => :batches, :action => :show, :id => result.fetch('id')
  end


  def assigned_objects
    respond_to do |format|
      format.js {
        raise "Not supported" unless params[:listing_only]

        criteria = params_for_backend_search

        response = JSONModel::HTTP.post_form("/repositories/#{session[:repo_id]}/batches/#{params[:id]}/search_objects",
                                             criteria)

        @search_data = SearchResultData.new(ASUtils.json_parse(response.body).merge(:criteria => criteria))

        render_aspace_partial(:partial => "batches/linked_objects_listing",
                              locals: {
                                filter_property: params[:filter_property],
                                filter_value: params[:filter_value]
                              })
      }
    end
  end

  def clear_assigned_objects
    JSONModel::HTTP.post_form("/repositories/#{session[:repo_id]}/batches/#{params[:id]}/clear_assigned_objects")

    redirect_to(:controller => :batches, :action => :assign_objects_form)
  end


  def csv
    self.response.headers['Content-Type'] = 'text/csv'
    self.response.headers['Content-Disposition'] = "attachment; filename=cr#{params[:id]}.csv"
    self.response.headers['Last-Modified'] = Time.now.ctime

    self.response_body = Enumerator.new do |stream|
      JSONModel::HTTP.stream("/repositories/#{session[:repo_id]}/batches/#{params[:id]}/csv") do |response|
        response.read_body do |chunk|
          stream << chunk
        end
      end
    end
  end


  def current_record
    @batch
  end

end
