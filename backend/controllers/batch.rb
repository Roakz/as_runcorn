class ArchivesSpaceService < Sinatra::Base

  Endpoint.get('/batch_action_handler/action_types')
    .description("List all Batch Action types")
    .params()
    .permissions([])
    .returns([200, '[action_types]']) \
  do
    json_response(Batch.action_types)
  end

  Endpoint.get('/repositories/:repo_id/batches')
    .description("List all Batches for indexing")
    .params(["repo_id", :repo_id])
    .paginated(true)
    .permissions([:index_system])
    .returns([200, '[:batch]']) \
  do
    handle_listing(Batch, params)
  end

  Endpoint.post('/repositories/:repo_id/batches')
    .description("Create a Batch")
    .params(["repo_id", :repo_id],
            ["batch", JSONModel(:batch), "The new record", :body => true])
    .permissions([])
    .returns([200, :created]) \
  do
    handle_create(Batch, params[:batch])
  end

  Endpoint.post('/repositories/:repo_id/batches/create_from_search')
    .description("Create a Batch and populate with the results of a search")
    .params(["repo_id", :repo_id],
            ["include_deaccessioned", BooleanParam, "Whether to include deaccessioned objects", :default => false],
            *BASE_SEARCH_PARAMS)
    .permissions([])
    .returns([200, :created]) \
  do
    note = 'Created from search results, excluding unspported models'
    note += ' and deaccessioned records' unless params[:include_deaccessioned]

    batch = Batch.create_from_json(JSONModel(:batch).from_hash({:note => note}))

    batch.include_deaccessioned(params[:include_deaccessioned])

    page = 1
    objs = {}

    sparms = params.merge(:page_size => 2**16,
                          :type => Batch.models,
                          :fields => ['primary_type', 'uri'],
                          :sort => 'primary_type asc')

    sr = Search.search(sparms.merge(:page => page), params[:repo_id])

    while !sr['results'].empty?
      sr['results'].each{|r| objs[r['primary_type']] ||= []; objs[r['primary_type']] << r['uri']}

      page = page += 1
      sr = Search.search(sparms.merge(:page => page), params[:repo_id])
    end

    objs.each do |model, uris|
      batch.add_by_ref(model, *uris)
    end

    created_response(batch)
  end

  Endpoint.post('/repositories/:repo_id/batches/:id')
    .description("Update a Batch")
    .params(["repo_id", :repo_id],
            ["id", :id],
            ["batch", JSONModel(:batch), "The updated record", :body => true])
    .permissions([])
    .returns([200, :updated]) \
  do
    handle_update(Batch, params[:id], params[:batch])
  end

  Endpoint.delete('/repositories/:repo_id/batches/:id')
    .description("Delete a Batch")
    .params(["repo_id", :repo_id],
            ["id", :id])
    .permissions([])
    .returns([200, :deleted]) \
  do
    handle_delete(Batch, params[:id])
  end

  Endpoint.get('/repositories/:repo_id/batches/:id')
    .description("Get a Batch by ID")
    .params(["repo_id", :repo_id],
            ["id", :id],
            ["resolve", :resolve])
    .permissions([])
    .returns([200, "(:batch)"]) \
  do

    json = Batch.to_jsonmodel(params[:id])
    json_response(resolve_references(json, params[:resolve]))
  end


  Endpoint.get('/repositories/:repo_id/batch_actions/:id')
    .description("Get a Batch Action by ID")
    .params(["repo_id", :repo_id],
            ["id", :id],
            ["resolve", :resolve])
    .permissions([])
    .returns([200, "(:batch_action)"]) \
  do

    json = BatchAction.to_jsonmodel(params[:id])
    json_response(resolve_references(json, params[:resolve]))
  end


  Endpoint.post('/repositories/:repo_id/batches/:id/assign_objects')
    .description("Add and remove objects from a batch")
    .params(["repo_id", :repo_id],
            ["model", String, "The type of objects to add/remove"],
            ["adds", [String], "List of references to add", :optional => true],
            ["removes", [String], "List of references to remove", :optional => true],
            ["include_deaccessioned", BooleanParam, "Whether to include deaccessioned objects", :default => false],
            ["id", :id])
    .permissions([])
    .returns([200, :updated]) \
  do
    batch = Batch.get_or_die(params[:id])

    batch.include_deaccessioned(params[:include_deaccessioned])

    batch.add_by_ref(params[:model], *Array(params[:adds]))
    batch.remove_by_ref(params[:model], *Array(params[:removes]))

    json_response("status" => "OK")
  end


  Endpoint.get('/repositories/:repo_id/batches/:id/object_refs')
    .description("Get the list of refs currently assign to a Batch")
    .params(["repo_id", :repo_id],
            ["id", :id])
    .permissions([])
    .returns([200, "[uri]"]) \
  do
    batch = Batch.get_or_die(params[:id])

    json_response(batch.object_refs)
  end


  Endpoint.post('/repositories/:repo_id/batches/:id/search_objects')
    .description("Search within assigned objects")
    .params(["repo_id", :repo_id],
            ["id", :id],
            *ArchivesSpaceService::BASE_SEARCH_PARAMS)
    .paginated(true)
    .permissions([])
    .returns([200, :updated]) \
  do
    # This (and a bunch of other stuff in batch object handling) is adapted from
    # Mr. Triggs' work on conservation requests. Thank you Mr. Triggs

    # This endpoint is here to show the user the (potentially many thousand)
    # objects that have been attached to their batch.
    #
    # We want to hit Solr to get the benefit of its performance, sorting and
    # pagination, but we can't rely on the objects we want having been
    # reindexed in time.  The use case here is:
    #
    #  * User adds a few thousand objects to a batch
    #
    #  * User immediately reloads the batch browse screen, which
    #    fires this search; and
    #
    #  * User expects to see the records they just added in the results
    #
    # Realtime indexing isn't *quite* realtime enough here, and we don't want to
    # make the user wait for the indexer to catch up.
    #
    # So, my (Mr. Triggs') goofy plan is: hit the DB to get the list of object model/IDs
    # attached to the batch, then use Solr's TermsQueryParser to
    # search by the ID set.
    # (https://lucene.apache.org/solr/guide/6_6/other-parsers.html#OtherParsers-TermsQueryParser)

    DB.open do |db|
      objects = db[:batch_objects]
        .filter(:batch_id => params[:id])
        .select(*Batch.id_columns)
        .map{|row|
          id_col = Batch.column_for_row(row)
          {:model => Batch.id_column_to_model(id_col), :id => row[id_col]}
      }

      # This endpoint supports all the usual search parameters, so we can set
      # the "q" parameter to build our magic query here.
      query = "{!terms f=id}"

      repo_id = params[:repo_id]
      objects.each_with_index do |obj, idx|
        query << "," if idx > 0
        query << JSONModel(obj[:model]).uri_for(obj[:id], :repo_id => repo_id)
      end

      params[:q] = query

      json_response(Search.search(params, repo_id))
    end
  end

  Endpoint.post('/repositories/:repo_id/batches/:id/remove_all_objects')
    .description("Clear all objects assigned to a batch")
    .params(["repo_id", :repo_id],
            ["id", :id])
    .permissions([])
    .returns([200, :updated]) \
  do
    batch = Batch.get_or_die(params[:id])
    batch.remove_all_objects

    json_response("status" => "OK")
  end


  Endpoint.post('/repositories/:repo_id/batches/:id/add_action/:action_type')
    .description("Adds an action to a batch")
    .params(["repo_id", :repo_id],
            ["id", :id],
            ["action_type", String, "The type of action to add"],
            ["action_params", String, "JSON containing the params for the action", :body => true])
    .permissions([])
    .returns([200, :updated]) \
  do
    batch = Batch.get_or_die(params[:id])

    action_params = params[:action_params].empty? ? '{}' : params[:action_params]
    batch.add_action(params[:action_type], ASUtils.json_parse(action_params))

    json_response("status" => "OK")
  end


  Endpoint.post('/repositories/:repo_id/batches/:id/propose')
    .description("Propose the current action for a batch for approval")
    .params(["repo_id", :repo_id],
            ["id", :id])
    .permissions([])
    .returns([200, :updated]) \
  do
    batch = Batch.get_or_die(params[:id])

    batch.update_action_status('proposed')

    json_response("status" => "OK")
  end


  Endpoint.post('/repositories/:repo_id/batches/:id/revert_to_draft')
    .description("Revert the current action for a batch to draft state")
    .params(["repo_id", :repo_id],
            ["id", :id])
    .permissions([])
    .returns([200, :updated]) \
  do
    batch = Batch.get_or_die(params[:id])

    batch.update_action_status('draft')

    json_response("status" => "OK")
  end


  Endpoint.post('/repositories/:repo_id/batches/:id/approve')
    .description("Approve the current action for a batch to be performed")
    .params(["repo_id", :repo_id],
            ["id", :id])
    .permissions([])
    .returns([200, :updated]) \
  do
    batch = Batch.get_or_die(params[:id])

    batch.update_action_status('approved')

    json_response("status" => "OK")
  end


  Endpoint.post('/repositories/:repo_id/batches/:id/delete_action')
    .description("Delete the current action for a batch")
    .params(["repo_id", :repo_id],
            ["id", :id])
    .permissions([])
    .returns([200, :updated]) \
  do
    batch = Batch.get_or_die(params[:id])

    batch.delete_current_action

    json_response("status" => "OK")
  end


  Endpoint.post('/repositories/:repo_id/batches/:id/dry_run')
    .description("Perform a dry run of the current action for a batch")
    .params(["repo_id", :repo_id],
            ["id", :id])
    .permissions([])
    .returns([200, :updated]) \
  do
    batch = Batch.get_or_die(params[:id])

    batch.perform_action(:commit => false)

    json_response("status" => "OK")
  end


  Endpoint.post('/repositories/:repo_id/batches/:id/perform_action')
    .description("Perform the current action for a batch")
    .params(["repo_id", :repo_id],
            ["id", :id])
    .permissions([])
    .returns([200, :updated]) \
  do
    batch = Batch.get_or_die(params[:id])

    batch.perform_action(:commit => true)

    json_response("status" => "OK")
  end


  Endpoint.get('/repositories/:repo_id/batches/:id/csv')
    .description("Download batch as a CSV document")
    .params(["repo_id", :repo_id],
            ["id", :id])
    .permissions([])
    .returns([200, "(csv)"]) \
  do
    batch = Batch.get_or_die(params[:id])

    [
      200,
      {"Content-Type" => "text/csv"},
      BatchCSV.for_refs(batch.object_refs).to_enum(:each_chunk)
    ]
  end


  Endpoint.get('/repositories/:repo_id/batch_actions/backlink_uri/:batch_action_id')
    .description("Get a ref for the batch containing a given batch action")
    .params(["repo_id", :repo_id],
            ["batch_action_id", Integer, "The requested ID"])
    .permissions([:view_repository])
    .returns([200, '{"ref": <id>}']) \
  do
    json_response({'ref' => BatchAction.batch_ref_for(params[:batch_action_id])})
  end

end
