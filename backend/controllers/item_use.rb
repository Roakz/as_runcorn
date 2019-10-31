class ArchivesSpaceService < Sinatra::Base

  Endpoint.get('/repositories/:repo_id/item_uses')
    .description("List all item uses for indexing")
    .params(["repo_id", :repo_id])
    .paginated(true)
    .permissions([:index_system])
    .returns([200, '[:item_use]']) \
  do
    handle_listing(ItemUse, params)
  end

  Endpoint.get('/repositories/:repo_id/item_uses/:id')
    .description("Get an Item Use by ID")
    .params(["repo_id", :repo_id],
            ["id", :id],
            ["resolve", :resolve])
    .permissions([])
    .returns([200, "(:item_use)"]) \
  do

    json = ItemUse.to_jsonmodel(params[:id])
    json_response(resolve_references(json, params[:resolve]))
  end
end


