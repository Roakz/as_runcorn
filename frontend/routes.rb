ArchivesSpace::Application.routes.draw do
  [AppConfig[:frontend_proxy_prefix], AppConfig[:frontend_prefix]].uniq.each do |prefix|
    scope prefix do
      match('agents/agent_corporate_entity/:id/managed_registration/submit' => 'managed_registration#submit', :via => [:get])
      match('agents/agent_corporate_entity/:id/managed_registration/withdraw' => 'managed_registration#withdraw', :via => [:get])
      match('agents/agent_corporate_entity/:id/managed_registration/approve' => 'managed_registration#approve', :via => [:get])
      match('agents/agent_corporate_entity/managed_registration/list' => 'managed_registration#index', :via => [:get])
    end
  end
end
