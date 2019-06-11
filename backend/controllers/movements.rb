class ArchivesSpaceService < Sinatra::Base

  Movements.models.each do |model|

    uri = model.my_jsonmodel.schema.fetch('uri')

    Endpoint.post("#{uri}/:id/move")
      .description("Record a movement")
      .params(["id", :id],
              ["repo_id", :repo_id],
              ["date", String, "Date/time of the move (default now)", :optional => true],
              ["location", String, "Location to move to (default HOME)", :optional => true],
              ["context", String, "uri for a context object", :optional => true])
      .permissions([])
      .returns([200, :updated]) \
    do
      obj = model.get_or_die(params[:id])

      obj.move(params.merge(:user => current_user.username))

      json = obj.class.to_jsonmodel(obj[:id])

      modified_response('Moved', obj.refresh)
    end
  end

end
