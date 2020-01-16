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
      match('representations/create_batch' => 'representations#create_batch', :via => [:post])

      resources :chargeable_items
      match('chargeable_items/index' => 'chargeable_items#index', :via => [:get])

      resources :chargeable_services
      match('chargeable_services/index' => 'chargeable_services#index', :via => [:get])

      match('deaccessions/affected_records' => 'deaccessions#affected_records', :via => [:get])

      match('raps/attach' => 'raps#attach_and_apply', :via => [:post])
      match('raps/attach' => 'raps#attach_form', :via => [:get])
      match('raps/summary' => 'raps#summary', :via => [:get])
      match('raps/attach_summary' => 'raps#attach_summary', :via => [:get])
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

      match('significant_items/index' => 'significant_items#index', :via => [:get])

      match('resources/:id/gaps_in_control' => 'resources#gaps_in_control', :via => [:get])

      match('top_containers/bulk_operations/update_functional_location' => 'top_containers#bulk_functional_location', :via => [:post])

      match('batches/create_from_search' => 'batches#create_from_search', :via => [:post])
      resources :batches
      match('batches/:id/assign_objects_form' => 'batches#assign_objects_form', :via => [:get])
      match('batches/:id/assign_objects' => 'batches#assign_objects', :via => [:post])
      match('batches/:id/assigned_objects' => 'batches#assigned_objects', :via => [:get])
      match('batches/:id/clear_assigned_objects' => 'batches#clear_assigned_objects', :via => [:post])
      match('batches/:id/add_action_form' => 'batches#add_action_form', :via => [:get])
      match('batches/:id/add_action' => 'batches#add_action', :via => [:post])
      match('batches/:id/dry_run' => 'batches#dry_run', :via => [:post])
      match('batches/:id/perform_action' => 'batches#perform_action', :via => [:post])
      match('batches/:id/delete_action' => 'batches#delete_action', :via => [:post])
      match('batches/:id/submit_for_review' => 'batches#submit_for_review', :via => [:post])
      match('batches/:id/revert_to_draft' => 'batches#revert_to_draft', :via => [:post])
      match('batches/:id/approve' => 'batches#approve', :via => [:post])
      match('batches/:id/delete' => 'batches#delete', :via => [:post])
      match('batches/:id' => 'batches#update', :via => [:post])
      match('batches/:id/csv' => 'batches#csv', :via => [:get])
      match('batch_actions/show/:id' => 'batch_actions#show', :via => [:get])

      match('item_uses/index' => 'item_uses#index', :via => [:get])

      match('runcorn_reports' => 'runcorn_reports#index', :via => [:get])
      match('runcorn_reports/generate_report' => 'runcorn_reports#generate_report', :via => [:post])
      match('runcorn_reports/locations_for_agency' => 'runcorn_reports#locations_for_agency', :via => [:get])
    end
  end
end
