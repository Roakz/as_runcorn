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
    resp = JSONModel::HTTP.post_form("/repositories/#{session[:repo_id]}/batches/#{params[:id]}/assign_objects",
                                     'model' => params[:model],
                                     'adds[]' => Array(params.dig(:batch_adds, 'ref')),
                                     'removes[]' => Array(params.dig(:batch_removes, 'ref')),
                                     'include_deaccessioned' => params[:include_deaccessioned])

    if resp.code === "200"
      flash[:success] = I18n.t("batch._frontend.messages.objects_assigned")
      redirect_to :controller => :batches, :action => :show
    else
      flash[:error] = error_message(:assign_objects, resp.body)
      redirect_to :controller => :batches, :action => :assign_objects_form
    end
  end

  def add_action_form
    @batch = JSONModel(:batch).find(params[:id], find_opts.merge('resolve[]' => RESOLVES))
  end

  def add_action
    resp = JSONModel::HTTP.post_form("/repositories/#{session[:repo_id]}/batches/#{params[:id]}/add_action/#{params[:action_type]}")

    if resp.code === "200"
      flash[:success] = I18n.t("batch._frontend.messages.action_added")
      redirect_to :controller => :batches, :action => :show
    else
      flash[:error] = error_message(:add_action, resp.body)
      redirect_to :controller => :batches, :action => :add_action_form
    end
  end

  def submit_for_review
    resp = JSONModel::HTTP.post_form("/repositories/#{session[:repo_id]}/batches/#{params[:id]}/propose")

    if resp.code === "200"
      flash[:success] = I18n.t("batch._frontend.messages.submitted_for_review")
    else
      flash[:error] = error_message(:submit_for_review, resp.body)
    end

    redirect_to :controller => :batches, :action => :show
  end

  def revert_to_draft
    resp = JSONModel::HTTP.post_form("/repositories/#{session[:repo_id]}/batches/#{params[:id]}/revert_to_draft")

    if resp.code === "200"
      flash[:success] = I18n.t("batch._frontend.messages.reverted_to_draft")
    else
      flash[:error] = error_message(:revert_to_draft, resp.body)
    end

    redirect_to :controller => :batches, :action => :show
  end

  def approve
    resp = JSONModel::HTTP.post_form("/repositories/#{session[:repo_id]}/batches/#{params[:id]}/approve")

    if resp.code === "200"
      flash[:success] = I18n.t("batch._frontend.messages.approved")
    else
      flash[:error] = error_message(:approve, resp.body)
    end

    redirect_to :controller => :batches, :action => :show
  end

  def delete_action
    resp = JSONModel::HTTP.post_form("/repositories/#{session[:repo_id]}/batches/#{params[:id]}/delete_action")

    if resp.code === "200"
      flash[:success] = I18n.t("batch._frontend.messages.action_deleted")
    else
      flash[:error] = error_message(:delete_action, resp.body)
    end

    redirect_to :controller => :batches, :action => :show
  end

  def dry_run
    resp = JSONModel::HTTP.post_form("/repositories/#{session[:repo_id]}/batches/#{params[:id]}/dry_run")

    if resp.code === "200"
      flash[:success] = I18n.t("batch._frontend.messages.dry_run_performed")
    else
      flash[:error] = error_message(:dry_run, resp.body)
    end

    redirect_to :controller => :batches, :action => :show
  end

  def perform_action
    resp = JSONModel::HTTP.post_form("/repositories/#{session[:repo_id]}/batches/#{params[:id]}/perform_action")

    if resp.code === "200"
      flash[:success] = I18n.t("batch._frontend.messages.action_performed")
    else
      flash[:error] = error_message(:perform_action, resp.body)
    end

    redirect_to :controller => :batches, :action => :show
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
    if (cap = batch.dig('current_action', 'action_params'))
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

    if params[:advanced]
      queries = advanced_search_queries

      queries = queries.reject{|field|
        if field['type'] === 'range'
          field['from'].nil? && field['to'].nil?
        elsif field['type'] === 'series_system'
          false
        else
          (field["value"].nil? || field["value"] == "") && !field["empty"]
        end
      }

      unless queries.empty?
        criteria["aq"] = AdvancedQueryBuilder.build_query_from_form(queries).to_json
      end
    end

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
    resp = JSONModel::HTTP.post_form("/repositories/#{session[:repo_id]}/batches/#{params[:id]}/remove_all_objects")

    if resp.code === "200"
      flash[:success] = I18n.t("batch._frontend.messages.batch_cleared")
    else
      flash[:error] = error_message(:clear, resp.body)
    end

    redirect_to :controller => :batches, :action => :assign_objects_form
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


  def error_message(action, error)
    out = I18n.t("batch._frontend.messages.error")
    out <<  I18n.t("batch._frontend.action.#{action}")
    out << " -- "
    begin
      out << ASUtils.json_parse(error)['error']
    rescue
      out << error
    end
    out
  end


  def current_record
    @batch
  end

end
