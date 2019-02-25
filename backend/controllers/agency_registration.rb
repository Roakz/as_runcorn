class ArchivesSpaceService < Sinatra::Base

  Endpoint.post('/agents/corporate_entities/:id/withdraw')
    .description("Revert agency to draft status")
    .params(["id", :id])
    .permissions([:update_agent_record])
    .returns([200, :state],
             [400, :error]) \
  do
    agency = AgentCorporateEntity.get_or_die(params[:id])

    agency.update(:registration_state => 'draft',
                  :registration_last_user => RequestContext.get(:current_username),
                  :registration_last_time => Time.now,
                  :publish => 0,
                  :user_mtime => Time.now,
                  :last_modified_by => RequestContext.get(:current_username))

    json_response({:state => "draft"})
  end


  Endpoint.post('/agents/corporate_entities/:id/submit')
    .description("Submit agency for registration approval")
    .params(["id", :id])
    .permissions([:update_agent_record])
    .returns([200, :state],
             [400, :error]) \
  do
    agency = AgentCorporateEntity.get_or_die(params[:id])

    agency.update(:registration_state => 'submitted',
                  :registration_last_user => RequestContext.get(:current_username),
                  :registration_last_time => Time.now,
                  :user_mtime => Time.now,
                  :last_modified_by => RequestContext.get(:current_username))

    json_response({:state => "submitted"})
  end


  Endpoint.post('/agents/corporate_entities/:id/approve')
    .description("Approve agency for registration")
    .params(["id", :id])
    .permissions([:approve_agency_registration])
    .returns([200, :state],
             [400, :error]) \
  do
    agency = AgentCorporateEntity.get_or_die(params[:id])

    agency.update(:registration_state => 'approved',
                  :registration_last_user => RequestContext.get(:current_username),
                  :registration_last_time => Time.now,
                  :user_mtime => Time.now,
                  :last_modified_by => RequestContext.get(:current_username))

    json_response({:state => "approved"})
  end




end
