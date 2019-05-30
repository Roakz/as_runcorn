class ArchivesSpaceService < Sinatra::Base
  Endpoint.post('/chargeable_services')
    .description("Create a Chargeable Service")
    .params(["chargeable_service", JSONModel(:chargeable_service), "The updated record", :body => true])
    .permissions([])
    .returns([200, :created]) \
  do
    handle_create(ChargeableService, params[:chargeable_service])
  end

  Endpoint.post('/chargeable_services/:id')
    .description("Update a Chargeable Service")
    .params(["id", :id],
            ["chargeable_service", JSONModel(:chargeable_service), "The updated record", :body => true])
    .permissions([])
    .returns([200, :updated]) \
  do
    handle_update(ChargeableService, params[:id], params[:chargeable_service])
  end

  Endpoint.delete('/chargeable_services/:id')
    .description("Delete a Chargeable Service")
    .params(["id", :id])
    .permissions([])
    .returns([200, :deleted]) \
  do
    handle_delete(ChargeableService, params[:id])
  end

  Endpoint.get('/chargeable_services/:id')
    .description("Get a Chargeable Service by ID")
    .params(["id", :id])
    .permissions([])
    .returns([200, "(:chargeable_service)"]) \
  do
    json_response(ChargeableService.to_jsonmodel(params[:id]))
  end

  Endpoint.get('/chargeable_services')
    .description("Get a list of Chargeable Services")
    .params(["resolve", :resolve])
    .permissions([])
    .returns([200, "[(:chargeable_service)]"]) \
  do
    handle_unlimited_listing(ChargeableService)
  end
end
