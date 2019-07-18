class ArchivesSpaceService < Sinatra::Base

  Endpoint.post('/raps/repositories/:repo_id/archival_objects/:id/attach_and_apply')
    .description("Attach and Apply a RAP")
    .params(["repo_id", :repo_id], 
            ["id", :id],
            ["rap", JSONModel(:rap), "The RAP record", :body =>true])
    .permissions([])
    .returns([200, :created]) \
  do
    attach_rap(ArchivalObject, params[:id], params[:rap])
  end

  Endpoint.post('/raps/repositories/:repo_id/physical_representations/:id/attach_and_apply')
    .description("Attach and Apply a RAP")
    .params(["repo_id", :repo_id],
            ["id", :id],
            ["rap", JSONModel(:rap), "The RAP record", :body =>true])
    .permissions([])
    .returns([200, :created]) \
  do
    attach_rap(PhysicalRepresentation, params[:id], params[:rap])
  end

  Endpoint.post('/raps/repositories/:repo_id/digital_representations/:id/attach_and_apply')
    .description("Attach and Apply a RAP")
    .params(["repo_id", :repo_id],
            ["id", :id],
            ["rap", JSONModel(:rap), "The RAP record", :body =>true])
    .permissions([])
    .returns([200, :created]) \
  do
    attach_rap(DigitalRepresentation, params[:id], params[:rap])
  end

  Endpoint.post('/raps/repositories/:repo_id/resources/:id/attach_and_apply')
    .description("Attach and Apply a RAP")
    .params(["repo_id", :repo_id],
            ["id", :id],
            ["rap", JSONModel(:rap), "The RAP record", :body =>true])
    .permissions([])
    .returns([200, :created]) \
  do
    attach_rap(Resource, params[:id], params[:rap])
  end

  Endpoint.get('/raps/repositories/:repo_id/resources/:id/summary')
    .description("RAPs and Representation counts")
    .params(["repo_id", :repo_id],
            ["id", :id],
            ["resolve", :resolve])
    .permissions([])
    .returns([200, "JSONModel(:rap_summary)"]) \
  do
    obj = Resource.get_or_die(params[:id])
    summary_json = obj.generate_rap_summary
    json_response(resolve_references(summary_json, params[:resolve]))
  end

  Endpoint.get('/raps/repositories/:repo_id/raps/:id')
    .description("RAP")
    .params(["repo_id", :repo_id],
            ["id", :id])
    .permissions([])
    .returns([200, "JSONModel(:rap_summary)"]) \
  do
    json_response(RAP.to_jsonmodel(params[:id]))
  end

  Endpoint.post('/raps/repositories/:repo_id/raps/:id')
    .description("RAP")
    .params(["repo_id", :repo_id],
            ["id", :id],
            ["rap", JSONModel(:rap), "The RAP record", :body =>true])
    .permissions([])
    .returns([200, "JSONModel(:rap_summary)"]) \
  do
    handle_update(RAP, params[:id], params[:rap])
  end

  Endpoint.post('/raps/repositories/:repo_id/check_tree_moves')
    .description("Check whether a given tree move would change RAP assignments")
    .permissions([])
    .use_transaction(false)
    .params(["repo_id", :repo_id],
            ["parent_uri", String, "A resource or AO uri"],
            ["node_uris", [String], "URIs of children"],
            ["position", Integer, "new position"])
    .returns([200, "Something helpful"]) \
  do
    raps_changed = RAP.does_movement_affect_raps(params[:parent_uri], params[:node_uris], params[:position])

    json_response({:status => raps_changed})
  end

  private

  def attach_rap(model_class, id, rap)
    obj = model_class.get_or_die(id)
    json = model_class.to_jsonmodel(obj)
    json['rap_attached'] = rap.to_hash
    obj.update_from_json(json)
    json_response({:status => 'ok'})
  end

end
