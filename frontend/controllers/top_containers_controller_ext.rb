TopContainersController.class_eval do

  @permission_mappings.fetch("manage_container_record") << :bulk_functional_location
  set_access_control(@permission_mappings)

  def bulk_functional_location
    post_uri = "/repositories/#{session[:repo_id]}/top_containers/batch/functional_location"
    post_params = {
      'ids[]' => params['update_uris'].map {|uri| JSONModel(:top_container).id_for(uri)},
      'location' => params['location']
    }
    response = JSONModel::HTTP::post_form(post_uri, post_params)
    result = ASUtils.json_parse(response.body)

    if result.has_key?('records_updated')
      render_aspace_partial :partial => "top_containers/bulk_operations/bulk_action_success", :locals => {:result => result}
    else
      render :text => "There seems to have been a problem with the update: #{result['error']}", :status => 500
    end
  end

end
