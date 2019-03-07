require 'db/migrations/utils'

Sequel.migration do

  up do
    create_table(:physical_representation) do
      primary_key :id
      Integer :lock_version, :default => 0, :null => false

      Integer :repo_id, :null => false

      Integer :archival_object_id
      Integer :resource_id

      DynamicEnum :access_category_id
      DynamicEnum :current_location_id
      DynamicEnum :normal_location_id
      DynamicEnum :access_clearance_procedure_id
      DynamicEnum :accessioned_status_id
      String :agency_assigned_id
      String :approval_date
      DynamicEnum :colour_id
      TextField :description
      Integer :file_issue_allowed
      DynamicEnum :format_id
      String :original_registration_date
      DynamicEnum :physical_description_type_id
      DynamicEnum :preservation_restriction_status_id
      String :title
      DynamicEnum :salvage_priority_code_id
      Integer :sterilised_status
      Integer :publish

      apply_mtime_columns
    end

    alter_table(:physical_representation) do
      add_foreign_key([:repo_id], :repository, :key => :id)
      add_foreign_key([:archival_object_id], :archival_object, :key => :id)
      add_foreign_key([:resource_id], :resource, :key => :id)
    end

    create_enum('runcorn_access_category', ['FIXME'])
    create_enum('runcorn_location', ['FIXME'])
    create_enum('runcorn_access_clearance_procedure', ['FIXME'])
    create_enum('runcorn_accessioned_status', ['FIXME'])
    create_enum('runcorn_colour', ['FIXME'])
    create_enum('runcorn_format', ['FIXME'])
    create_enum('runcorn_physical_description_type', ['FIXME'])
    create_enum('runcorn_physical_preservation_restriction_status', ['FIXME'])
    create_enum('runcorn_salvage_priority_code', ['FIXME'])

    create_table(:representation_approved_by_rlshp) do
      primary_key :id

      Integer :physical_representation_id
      Integer :agent_person_id

      Integer :aspace_relationship_position

      apply_mtime_columns(false)
    end

    alter_table(:representation_approved_by_rlshp) do
      add_foreign_key([:physical_representation_id], :physical_representation, :key => :id)
      add_foreign_key([:agent_person_id], :agent_person, :key => :id)
    end

    alter_table(:deaccession) do
      add_column(:physical_representation_id, :integer,  :null => true)
      add_foreign_key([:physical_representation_id], :physical_representation, :key => :id, :name => 'deaccession_physrep_id_fk')
    end

    alter_table(:extent) do
      add_column(:physical_representation_id, :integer,  :null => true)
      add_foreign_key([:physical_representation_id], :physical_representation, :key => :id, :name => 'extent_physrep_id_fk')
    end

    alter_table(:note) do
      add_column(:physical_representation_id, :integer,  :null => true)
      add_foreign_key([:physical_representation_id], :physical_representation, :key => :id, :name => 'note_physrep_id_fk')
    end

    alter_table(:external_id) do
      add_column(:physical_representation_id, :integer,  :null => true)
      add_foreign_key([:physical_representation_id], :physical_representation, :key => :id, :name => 'external_id_physrep_id_fk')
    end
  end

  down do
  end

end
