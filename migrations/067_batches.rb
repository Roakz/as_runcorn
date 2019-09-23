require 'db/migrations/utils'

Sequel.migration do

  up do
    create_enum('runcorn_batch_action_status',
                [
                 'draft',
                 'proposed',
                 'approved',
                 'executed',
                ])

    create_enum('runcorn_batch_model',
                [
                 'agent_corporate_entity',
                 'resource',
                 'archival_object',
                 'physical_representation',
                 'digital_representation',
                 'top_container',
                ])

    create_table(:batch) do
      primary_key :id

      Integer :lock_version, :default => 0, :null => false
      Integer :json_schema_version, :null => false

      TextField :note, :null => true

      apply_mtime_columns
    end

    create_table(:batch_action) do
      primary_key :id

      Integer :lock_version, :default => 0, :null => false
      Integer :json_schema_version, :null => false

      DynamicEnum :action_status_id, :null => false

      TextField :note, :null => true

      String :action_type, :null => false
      String :action_params, :null => true
      String :approved_user, :null => true
      DateTime :approved_time, :null => true
      String :action_user, :null => false
      DateTime :action_time, :null => true

      apply_mtime_columns
    end

    create_table(:batch_action_batch_rlshp) do
      primary_key :id

      Integer :batch_action_id
      Integer :batch_id
      Integer :aspace_relationship_position
      Integer :suppressed, :default => 0

      apply_mtime_columns(false)
    end

    alter_table(:batch_action_batch_rlshp) do
      add_foreign_key([:batch_action_id], :batch_action, :key => :id)
      add_foreign_key([:batch_id], :batch, :key => :id)
    end

    create_table(:batch_objects) do
      primary_key :id

      Integer :batch_id, :null => false

      Integer :agent_corporate_entity_id
      Integer :resource_id
      Integer :archival_object_id
      Integer :physical_representation_id
      Integer :digital_representation_id
      Integer :top_container_id
    end

    alter_table(:batch_objects) do
      add_foreign_key([:batch_id], :batch, :key => :id)
      add_foreign_key([:agent_corporate_entity_id], :agent_corporate_entity, :key => :id)
      add_foreign_key([:resource_id], :resource, :key => :id)
      add_foreign_key([:archival_object_id], :archival_object, :key => :id)
      add_foreign_key([:physical_representation_id], :physical_representation, :key => :id)
      add_foreign_key([:digital_representation_id], :digital_representation, :key => :id)
      add_foreign_key([:top_container_id], :top_container, :key => :id)
    end

  end

end
