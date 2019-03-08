class DigitalRepresentationsController < ApplicationController

  set_access_control "view_repository" => [:show]


  def show
    digital_representation_id = Integer(params[:id])

    record_uri = JSONModel::HTTP.get_json("/repositories/#{session[:repo_id]}/digital_representations/backlink_uri/#{digital_representation_id}").fetch('ref')

    resolver = Resolver.new(record_uri)

    # FIXME: jump to the right subrecord section
    redirect_to resolver.view_uri
  end

end
