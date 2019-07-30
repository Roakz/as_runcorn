AssessmentsController.class_eval do

  @permission_mappings.fetch("update_assessment_record") << :from_conservation_request
  @permission_mappings.fetch("update_assessment_record") << :linked_representations
  @permission_mappings.fetch("update_assessment_record") << :csv
  set_access_control(@permission_mappings)

  def new
    @assessment = JSONModel(:assessment).new._always_valid!
    @assessment.survey_begin ||= Date.today.strftime('%Y-%m-%d')
    @assessment_attribute_definitions = AssessmentAttributeDefinitions.find(nil)

    if params[:conservation_request_uri]
      @assessment.conservation_request_id = JSONModel.parse_reference(params[:conservation_request_uri]).fetch(:id)
    end
  end

  def linked_representations
    respond_to do |format|
      format.js {
        raise "Not supported" unless params[:listing_only]

        criteria = params_for_backend_search

        response = JSONModel::HTTP.post_form("/repositories/#{session[:repo_id]}/assessments/#{params[:id]}/search_assigned_records",
                                             criteria)

        @search_data = SearchResultData.new(ASUtils.json_parse(response.body).merge(:criteria => criteria))

        # NOTE: Re-using the same partial for now since they're the same.
        render_aspace_partial(:partial => "conservation_requests/linked_representations_listing",
                              locals: {
                                filter_property: params[:filter_property],
                                filter_value: params[:filter_value]
                              })
      }
    end
  end

  def csv
    self.response.headers['Content-Type'] = 'text/csv'
    self.response.headers['Content-Disposition'] = "attachment; filename=assessment_#{params[:id]}.csv"
    self.response.headers['Last-Modified'] = Time.now.ctime

    self.response_body = Enumerator.new do |stream|
      JSONModel::HTTP.stream("/repositories/#{session[:repo_id]}/assessments/#{params[:id]}/csv") do |response|
        response.read_body do |chunk|
          stream << chunk
        end
      end
    end
  end

end
