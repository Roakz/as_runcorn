class ArchivesSpaceService < Sinatra::Base
  Endpoint.post('/repositories/:repo_id/assessments/:id/search_assigned_records')
    .description("Search within assigned records")
    .params(["repo_id", :repo_id],
            ["id", :id],
            *ArchivesSpaceService::BASE_SEARCH_PARAMS)
    .paginated(true)
    .permissions([])
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

    json_response(Search.search(params, params[:repo_id]))
  end

<<<<<<< HEAD
  Endpoint.get('/repositories/:repo_id/assessments/:id/csv')
    .description("Download assessment representations as a CSV document")
    .params(["repo_id", :repo_id],
            ["id", :id])
    .permissions([])
    .returns([200, "(csv)"]) \
  do
    assessment = Assessment.get_or_die(params[:id])

    [
      200,
      {"Content-Type" => "text/csv"},
      ConservationCSV.for_refs(assessment.connected_record_refs).to_enum(:each_chunk)
    ]
  end


=======
  Endpoint.post('/repositories/:repo_id/assessments/:id/generate_treatments')
    .description("Generate a treatment subrecord on the provided representations")
    .params(["repo_id", :repo_id],
            ["id", :id],
            ["representation_id", [Integer], "Representation QSA IDs"])
    .permissions([])
    .returns([200, :updated]) \
  do
    assessment = Assessment.get_or_die(params[:id])

    if assessment.check_if_assessed?(params[:representation_id])
      begin
        PhysicalRepresentation.generate_treatments!(params[:representation_id])
        json_response({:status => 'success', :errors => []})
      rescue
        json_response({:status => 'error', :errors => ["Error generating treatments: #{$!}"]})
      end
    else
      json_response({:status => 'error', :errors => ['One or more Representation IDs are not linked to this assessment']})
    end
  end
>>>>>>> First go at generating treatments from an assessment
end
