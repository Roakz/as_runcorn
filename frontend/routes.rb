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

      resources :chargeable_items
      match('chargeable_items/index' => 'chargeable_items#index', :via => [:get])

      resources :chargeable_services
      match('chargeable_services/index' => 'chargeable_services#index', :via => [:get])

      match('deaccessions/affected_records' => 'deaccessions#affected_records', :via => [:get])

      match('raps/attach' => 'raps#attach_and_apply', :via => [:post])
      match('raps/attach' => 'raps#attach_form', :via => [:get])
      match('raps/summary' => 'raps#summary', :via => [:get])
      match('raps/edit' => 'raps#edit', :via => [:get])
      match('raps/update' => 'raps#update', :via => [:post])
      match('raps/check_tree_move' => 'raps#check_tree_move', :via => [:post])

      resources :conservation_requests
      match('conservation_requests/:id/assign_records_form' => 'conservation_requests#assign_records_form', :via => [:get])
      match('conservation_requests/:id/assign_records' => 'conservation_requests#assign_records', :via => [:post])
      match('conservation_requests/:id/linked_representations' => 'conservation_requests#linked_representations', :via => [:get])
      match('conservation_requests/:id/clear_assigned_records' => 'conservation_requests#clear_assigned_records', :via => [:post])
      match('conservation_requests/:id/submit_for_review' => 'conservation_requests#submit_for_review', :via => [:post])
      match('conservation_requests/:id/revert_to_draft' => 'conservation_requests#revert_to_draft', :via => [:post])
      match('conservation_requests/:id/delete' => 'conservation_requests#delete', :via => [:post])
      match('conservation_requests/:id' => 'conservation_requests#update', :via => [:post])
      match('conservation_requests/:id/spawn_assessment' => 'conservation_requests#spawn_assessment', :via => [:get])
      match('conservation_requests/:id/csv' => 'conservation_requests#csv', :via => [:get])

      match('assessments/:id/linked_representations' => 'assessments#linked_representations', :via => [:get])
      match('assessments/:id/csv' => 'assessments#csv', :via => [:get])
      match('assessments/:id/generate_treatments' => 'assessments#generate_treatments', :via => [:get, :post])
    end
  end
end
