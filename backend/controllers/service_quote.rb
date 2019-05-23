class ArchivesSpaceService < Sinatra::Base
  Endpoint.post('/service_quotes/:id')
    .description("Update a Service quote")
    .params(["id", :id],
            ["service_quote", JSONModel(:service_quote), "The updated record", :body => true])
    .permissions([])
    .returns([200, :updated]) \
  do
    handle_update(ServiceQuote, params[:id], params[:service_quote])
  end

  Endpoint.get('/service_quotes/:id')
    .description("Get a Service quote by ID")
    .params(["id", :id])
    .permissions([])
    .returns([200, "(:service_quote)"]) \
  do
    json_response(ServiceQuote.to_jsonmodel(params[:id]))
  end
end
