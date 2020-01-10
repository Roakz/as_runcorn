class ArchivesSpaceService < Sinatra::Base

  Endpoint.get('/repositories/:repo_id/conservation_requests')
    .description("List all conservation requests for indexing")
    .params(["repo_id", :repo_id])
    .paginated(true)
    .permissions([:index_system])
    .returns([200, '[:conservation_request]']) \
  do
    handle_listing(ConservationRequest, params)
  end

  Endpoint.post('/repositories/:repo_id/conservation_requests')
    .description("Create a Conservation Request")
    .params(["repo_id", :repo_id],
            ["conservation_request", JSONModel(:conservation_request), "The updated record", :body => true])
    .permissions([:manage_conservation_assessment])
    .returns([200, :created]) \
  do
    handle_create(ConservationRequest, params[:conservation_request])
  end

  Endpoint.post('/repositories/:repo_id/conservation_requests/:id')
    .description("Update a Conservation Request")
    .params(["repo_id", :repo_id],
            ["id", :id],
            ["conservation_request", JSONModel(:conservation_request), "The updated record", :body => true])
    .permissions([:manage_conservation_assessment])
    .returns([200, :updated]) \
  do
    handle_update(ConservationRequest, params[:id], params[:conservation_request])
  end

  Endpoint.delete('/repositories/:repo_id/conservation_requests/:id')
    .description("Delete a Conservation Request")
    .params(["repo_id", :repo_id],
            ["id", :id])
    .permissions([:manage_conservation_assessment])
    .returns([200, :deleted]) \
  do
    handle_delete(ConservationRequest, params[:id])
  end

  Endpoint.get('/repositories/:repo_id/conservation_requests/:id')
    .description("Get a Conservation Request by ID")
    .params(["repo_id", :repo_id],
            ["id", :id],
            ["resolve", :resolve])
    .permissions([:view_repository])
    .returns([200, "(:conservation_request)"]) \
  do

    json = ConservationRequest.to_jsonmodel(params[:id])
    json_response(resolve_references(json, params[:resolve]))
  end

  Endpoint.post('/repositories/:repo_id/conservation_requests/:id/assign_records')
    .description("Add and remove records from a conservation request")
    .params(["repo_id", :repo_id],
            ["adds", [String], "List of references to add", :optional => true],
            ["removes", [String], "List of references to remove", :optional => true],
            ["id", :id])
    .permissions([:manage_conservation_assessment])
    .returns([200, :updated]) \
  do
    conservation_request = ConservationRequest.get_or_die(params[:id])

    conservation_request.add_by_ref(*Array(params[:adds]))
    conservation_request.remove_by_ref(*Array(params[:removes]))

    json_response("status" => "OK")
  end

  Endpoint.post('/repositories/:repo_id/conservation_requests/:id/search_assigned_records')
    .description("Search within assigned records")
    .params(["repo_id", :repo_id],
            ["id", :id],
            *ArchivesSpaceService::BASE_SEARCH_PARAMS)
    .paginated(true)
    .permissions([:view_repository])
    .returns([200, :updated]) \
  do
    # This endpoint is here to show the user the (potentially many thousand)
    # records that have been attached to their conservation request.
    #
    # We want to hit Solr to get the benefit of its performance, sorting and
    # pagination, but we can't rely on the representations we want having been
    # reindexed in time.  The use case here is:
    #
    #  * User adds a few thousand representations to a conservation request
    #
    #  * User immediately reloads the conservation request browse screen, which
    #    fires this search; and
    #
    #  * User expects to see the records they just added in the results
    #
    # Realtime indexing isn't *quite* realtime enough here, and we don't want to
    # make the user wait for the indexer to catch up.
    #
    # So, my goofy plan is: hit the DB to get the list of representation IDs
    # attached to the conservation request, then use Solr's TermsQueryParser to
    # search by the ID set.
    # (https://lucene.apache.org/solr/guide/6_6/other-parsers.html#OtherParsers-TermsQueryParser)

    DB.open do |db|
      physical_representation_ids = db[:conservation_request_representations]
        .filter(:conservation_request_id => params[:id])
        .select(:physical_representation_id)
        .map {|row| row[:physical_representation_id]}

      # This endpoint supports all the usual search parameters, so we can set
      # the "q" parameter to build our magic query here.
      query = "{!terms f=id}"

      repo_id = params[:repo_id]
      physical_representation_ids.each_with_index do |id, idx|
        query << "," if idx > 0
        query << JSONModel(:physical_representation).uri_for(id, :repo_id => repo_id)
      end

      params[:q] = query

      json_response(Search.search(params, repo_id))
    end
  end

  Endpoint.post('/repositories/:repo_id/conservation_requests/:id/clear_assigned_records')
    .description("Clear all records assigned to a conservation request")
    .params(["repo_id", :repo_id],
            ["id", :id])
    .permissions([:manage_conservation_assessment])
    .returns([200, :updated]) \
  do
    conservation_request = ConservationRequest.get_or_die(params[:id])
    conservation_request.clear_assigned_records
  end


  Endpoint.get('/repositories/:repo_id/conservation_requests/:id/csv')
    .description("Download conservation request as a CSV document")
    .params(["repo_id", :repo_id],
            ["id", :id])
    .permissions([:view_repository])
    .returns([200, "(csv)"]) \
  do
    conservation_request = ConservationRequest.get_or_die(params[:id])

    [
      200,
      {"Content-Type" => "text/csv"},
      ConservationCSV.for_refs(conservation_request.assigned_representation_refs).to_enum(:each_chunk)
    ]
  end

end
