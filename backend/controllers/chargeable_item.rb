class ArchivesSpaceService < Sinatra::Base
  Endpoint.post('/chargeable_items')
    .description("Create a Chargeable Item")
    .params(["chargeable_item", JSONModel(:chargeable_item), "The updated record", :body => true])
    .permissions([:update_charges])
    .returns([200, :created]) \
  do
    handle_create(ChargeableItem, params[:chargeable_item])
  end

  Endpoint.post('/chargeable_items/:id')
    .description("Update a Chargeable Item")
    .params(["id", :id],
            ["chargeable_item", JSONModel(:chargeable_item), "The updated record", :body => true])
    .permissions([:update_charges])
    .returns([200, :updated]) \
  do
    handle_update(ChargeableItem, params[:id], params[:chargeable_item])
  end

  Endpoint.delete('/chargeable_items/:id')
    .description("Delete a Chargeable Item")
    .params(["id", :id])
    .permissions([:update_charges])
    .returns([200, :deleted]) \
  do
    handle_delete(ChargeableItem, params[:id])
  end

  Endpoint.get('/chargeable_items/:id')
    .description("Get a Chargeable Item by ID")
    .params(["id", :id])
    .permissions([])
    .returns([200, "(:chargeable_item)"]) \
  do
    json_response(ChargeableItem.to_jsonmodel(params[:id]))
  end

  Endpoint.get('/chargeable_items')
    .description("Get a list of Chargeable Items")
    .params()
    .paginated(true)
    .permissions([])
    .returns([200, "[(:chargeable_item)]"]) \
  do
    handle_listing(ChargeableItem, params)
  end
end
