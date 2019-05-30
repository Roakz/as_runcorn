ArchivesSpace::Application.routes.draw do
  [AppConfig[:frontend_proxy_prefix], AppConfig[:frontend_prefix]].uniq.each do |prefix|
    scope prefix do
      match('agents/agent_corporate_entity/:id/managed_registration/submit' => 'managed_registration#submit', :via => [:get])
      match('agents/agent_corporate_entity/:id/managed_registration/withdraw' => 'managed_registration#withdraw', :via => [:get])
      match('agents/agent_corporate_entity/:id/managed_registration/approve' => 'managed_registration#approve', :via => [:get])
      match('agents/agent_corporate_entity/managed_registration/list' => 'managed_registration#index', :via => [:get])
      match('physical_representations/show/:id' => 'physical_representations#show', :via => [:get])
      match('digital_representations/show/:id' => 'digital_representations#show', :via => [:get])
      match('representations/index' => 'representations#index', :via => [:get])
      match('representations/view_file' => 'representations#view_file', :via => [:get])
      match('representations/upload_file' => 'representations#upload_file', :via => [:post])

      match('chargeable_items/index' => 'chargeable_items#index', :via => [:get])
      match('chargeable_services/index' => 'chargeable_services#index', :via => [:get])
    end
  end
end
