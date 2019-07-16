class RapsController < ApplicationController

  set_access_control  "view_repository" => [:attach_and_apply, :attach_form, :summary]

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

end