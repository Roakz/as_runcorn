class RepresentationsController < ApplicationController

  set_access_control "view_repository" => [:index, :view_file, :upload_file]

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

  def view_file
    self.response.headers["Content-Type"] = params[:mime_type]
    self.response.headers['Last-Modified'] = Time.now.ctime

    self.response_body = Enumerator.new do |stream|
      JSONModel::HTTP.stream("/repositories/#{session[:repo_id]}/digital_representations/view_file",
                             :key => params[:key]) do |response|
        response.read_body do |chunk|
          stream << chunk
        end
      end
    end
  end

  def upload_file
    response = JSONModel::HTTP.post_form("/repositories/#{session[:repo_id]}/digital_representations/upload_file",
                                         {
                                           :file => UploadIO.new(params[:file].tempfile,
                                                                 params[:file].content_type,
                                                                 params[:file].original_filename),
                                         },
    :multipart_form_data)

    raise unless response.code == '200'

    json = ASUtils.json_parse(response.body)

    render :json => {
             "status" => "success",
             "filename" => params[:file].original_filename,
             "mime_type" => params[:file].content_type,
             "key" => json['key'],
           },
           :status => '200'
  end

end
