class ArchivesSpaceService < Sinatra::Base
  Endpoint.post('/repositories/:repo_id/assessments/:id/search_assigned_records')
    .description("Search within assigned records")
    .params(["repo_id", :repo_id],
            ["id", :id],
            *ArchivesSpaceService::BASE_SEARCH_PARAMS)
    .paginated(true)
    .permissions([:view_repository])
    .returns([200, :updated]) \
  do
    # See the corresponding `search` method in conservation_request.rb for an
    # explanation of what's going on here.
    query = "{!terms f=id}"

    assessment = Assessment.get_or_die(params[:id])
    assessment.connected_record_refs.each_with_index do |uri, idx|
      query << ',' if idx > 0
      query << uri
    end

    params[:q] = query

    results = Search.search(params, params[:repo_id])

    Assessment.add_treatment_summaries_to_search_results(assessment.id, results)

    json_response(results)
  end

  Endpoint.get('/repositories/:repo_id/assessments/:id/csv')
    .description("Download assessment representations as a CSV document")
    .params(["repo_id", :repo_id],
            ["id", :id])
    .permissions([:view_repository])
    .returns([200, "(csv)"]) \
  do
    assessment = Assessment.get_or_die(params[:id])

    [
      200,
      {"Content-Type" => "text/csv"},
      AssessmentCSV.for_refs(assessment.id, assessment.connected_record_refs).to_enum(:each_chunk)
    ]
  end


  Endpoint.post('/repositories/:repo_id/assessments/:id/generate_treatments')
    .description("Generate a treatment subrecord on the provided representations")
    .params(["repo_id", :repo_id],
            ["id", :id],
            ["representation_id", [Integer], "Representation QSA IDs"],
            ["conservation_treatment", String, "Conservation Treatment template"])
    .permissions([:manage_conservation_assessment])
    .returns([200, :updated]) \
  do
    assessment = Assessment.get_or_die(params[:id])
    treatment_template = ASUtils.json_parse(params[:conservation_treatment] || {})

    if assessment.check_if_assessed?(params[:representation_id])
      begin
        PhysicalRepresentation.generate_treatments!(params[:representation_id], assessment.id, treatment_template)
        json_response({:status => 'success', :errors => []})
      rescue
        json_response({:status => 'error', :errors => ["Error generating treatments: #{$!}"]})
      end
    else
      json_response({:status => 'error', :errors => ['One or more Representation IDs are not linked to this assessment']})
    end
  end
end
