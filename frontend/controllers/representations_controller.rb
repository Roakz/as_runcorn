class RepresentationsController < ApplicationController

  set_access_control "view_repository" => [:index, :view_file, :upload_file, :create_batch]

  REPRESENTATION_FACETS = [
    'primary_type',
    'publish',
    'archivist_approved_u_sbool',
    'representation_intended_use_u_sstr',
    'significance_u_sstr',
    'rap_open_access_metadata_u_ssort',
    'rap_access_status_u_ssort',
    'rap_access_category_u_ssort',
    'conservation_awaiting_treatment_u_sbool',
    'conservation_treatment_in_progress_u_sbool',
  ] + Plugins.search_facets_for_type(:digital_representation) + Plugins.search_facets_for_type(:physical_representation)

  def index
    (search_params, expiring_within) = build_search_params

    respond_to do |format|
      format.html {
        @search_data = Search.for_type(session[:repo_id], ['physical_representation', 'digital_representation'], search_params)

        # If we dropped the filter_term out, add it back so the results page looks right.
        if expiring_within
          @search_data[:criteria]['filter_term[]'] << expiring_within
        end
      }
      format.csv {
        search_params["type[]"] = ['physical_representation', 'digital_representation']
        uri = "/repositories/#{session[:repo_id]}/search"
        csv_response( uri, search_params )
      }
    end
  end


  def build_search_params
    search_params = params_for_backend_search.merge("facet[]" => REPRESENTATION_FACETS)

    expiring_days = nil

    expiring_within = nil

    if search_params['filter_term[]']
      if expiring_within = search_params['filter_term[]'].find {|term| JSON.parse(term).keys[0] == 'rap_expiring_within'}
        search_params['filter_term[]'].delete(expiring_within)

        expiring_days = JSON.parse(expiring_within).values[0]
      end
    end

    if expiring_days
      start_date, end_date = [Date.today, Date.today + expiring_days].sort

      query = {'query' => {
                 'jsonmodel_type' => 'boolean_query',
                 'op' => 'AND',
                 'subqueries' => [
                   {
                     'jsonmodel_type' => 'date_field_query',
                     'comparator' => 'greater_than',
                     'field' => 'rap_expiry_date_sort_u_ssortdate',
                     'value' => "%sT00:00:00Z" % [start_date.iso8601],
                   },
                   {
                     'jsonmodel_type' => 'date_field_query',
                     'comparator' => 'lesser_than',
                     'field' => 'rap_expiry_date_sort_u_ssortdate',
                     'value' => "%sT00:00:00Z" % [end_date.iso8601],
                   }
                 ]
               }
              }

      search_params['filter'] = JSONModel(:advanced_query).from_hash(query).to_json
    end

    [search_params, expiring_within]
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


  def create_batch
    post_uri = URI("/repositories/#{session[:repo_id]}/batches/create_from_search")

    (search_params, expiring_within) = build_search_params
    search_params["type[]"] = ['physical_representation', 'digital_representation']

    Search.build_filters(search_params)
    response = JSONModel::HTTP.post_form(post_uri, search_params)
    result = ASUtils.json_parse(response.body)

    flash[:success] = I18n.t("batch._frontend.messages.created")
    redirect_to :controller => :batches, :action => :show, :id => result.fetch('id')
  end

end
