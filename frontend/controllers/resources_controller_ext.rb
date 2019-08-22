ResourcesController.class_eval do

  @permission_mappings.fetch("view_repository") << :gaps_in_control
  set_access_control(@permission_mappings)

  def gaps_in_control
    resource_uri = JSONModel(:resource).uri_for(params[:id])
    gaps_in_control = JSONModel::HTTP.get_json("#{resource_uri}/gaps_in_control")
    render_aspace_partial :partial => "resources/gaps_in_control", :locals => {:gaps_in_control => gaps_in_control}
  end

end