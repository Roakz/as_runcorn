class RapsController < ApplicationController

  set_access_control  "set_raps" => [:attach_and_apply, :attach_form, :edit, :update, :attach_summary],
                      "view_repository" => [:summary, :check_tree_move]

  def attach_and_apply
    rap_data = cleanup_params_for_schema(params[:rap], JSONModel(:rap).schema)
    rap_json = JSONModel(:rap).from_hash(rap_data, false, false)

    if rap_json._exceptions.empty?
      post_uri = URI("#{JSONModel::HTTP.backend_url}/raps#{params[:uri]}/attach_and_apply")
      resp = JSONModel::HTTP.post_json(post_uri, rap_json.to_json)

      if resp.code === "200"
        render :plain => 'success', :status => 200
        flash[:success] = I18n.t("rap_attached.success_message")
      else
        flash.now[:error] = resp.body
        render_aspace_partial :partial => 'rap_attached/form', :locals => {rap: rap_json, uri: params[:uri]}, :status => 500
      end
    else
      @exceptions = rap_json._exceptions
      render_aspace_partial :partial => 'rap_attached/form', :locals => {rap: rap_json, uri: params[:uri]}, :status => 500
    end
  end

  def attach_form
    render_aspace_partial :partial => 'rap_attached/form', :locals => {rap: JSONModel(:rap).new, uri: params[:uri]}
  end

  def summary
    summary = JSONModel(:rap_summary).from_hash(JSONModel::HTTP.get_json("/raps#{params[:uri]}/summary", "resolve[]" => ['rap', 'attached_to']), false, true)
    render_aspace_partial :partial => 'raps_summary/summary', :locals => {summary: summary}
  end

  def edit
    rap = JSONModel(:rap).from_hash(JSONModel::HTTP.get_json("/raps#{params[:rap_uri]}"), false, true)
    render_aspace_partial :partial => 'rap_attached/form', :locals => {form_action: :update, rap: rap, uri: params[:uri]}
  end

  def update
    rap_uri = params[:rap_uri]
    rap_data = cleanup_params_for_schema(params[:rap], JSONModel(:rap).schema)
    rap_json = JSONModel(:rap).from_hash(rap_data, false, false)

    if rap_json._exceptions.empty?
      post_uri = URI("#{JSONModel::HTTP.backend_url}/raps#{rap_uri}")
      resp = JSONModel::HTTP.post_json(post_uri, rap_json.to_json)

      if resp.code === "200"
        render :plain => 'success', :status => 200
        flash[:success] = I18n.t("rap_attached.update_success_message")
      else
        flash.now[:error] = resp.body
        rap_json['uri'] = rap_uri
        render_aspace_partial :partial => 'rap_attached/form', :locals => {form_action: :update, rap: rap_json, uri: params[:uri]}, :status => 500
      end
    else
      @exceptions = rap_json._exceptions
      rap_json['uri'] = rap_uri
      render_aspace_partial :partial => 'rap_attached/form', :locals => {form_action: :update, rap: rap_json, uri: params[:uri]}, :status => 500
    end
  end

  def check_tree_move
    params[:parent_uri]
    params[:node_uris]
    params[:position]

    response = JSONModel::HTTP.post_form("/raps/repositories/#{session[:repo_id]}/check_tree_moves",
                                         'parent_uri' => params[:parent_uri],
                                         'node_uris[]' => params[:node_uris],
                                         'position' => params[:position])

    render :json => response.body
  end

  def attach_summary
    summary = JSONModel::HTTP.get_json("/raps/attach_summary", uri: params[:uri])
    render_aspace_partial :partial => 'raps_summary/attach_summary', :locals => {summary: summary}
  end

end
