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

  private

  def attach_rap(model_class, id, rap)
    obj = model_class.get_or_die(id)
    json = model_class.to_jsonmodel(obj)
    json['rap_attached'] = rap.to_hash
    obj.update_from_json(json)
    json_response({:status => 'ok'})
  end

end
