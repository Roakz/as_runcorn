require 'db/migrations/utils'

Sequel.migration do

  up do

    create_table(:conservation_treatment) do
      primary_key :id
      apply_mtime_columns

      Integer :lock_version, :default => 0, :null => false
      Integer :json_schema_version, :null => false

      Integer :physical_representation_id, :null => false

      String :status, :null => false
      String :start_date
      String :end_date

      TextField :treatment_process
      TextField :materials_used_consumables
      TextField :materials_used_staff_time

      String :external_reference
    end

    alter_table(:conservation_treatment) do
      add_foreign_key([:physical_representation_id], :physical_representation, :key => :id)
    end

    create_table(:conservation_treatment_user_rlshp) do
      primary_key :id

      Integer :conservation_treatment_id
      Integer :agent_person_id

      Integer :suppressed, :default => 0
      Integer :aspace_relationship_position

      apply_mtime_columns(false)
    end

    alter_table(:conservation_treatment_user_rlshp) do
      add_foreign_key([:conservation_treatment_id], :conservation_treatment, :key => :id)
      add_foreign_key([:agent_person_id], :agent_person, :key => :id)
    end

  end
end
