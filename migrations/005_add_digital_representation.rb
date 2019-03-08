require 'db/migrations/utils'

Sequel.migration do

  up do
    create_table(:digital_representation) do
      primary_key :id
      Integer :lock_version, :default => 0, :null => false

      Integer :repo_id, :null => false

      Integer :archival_object_id
      Integer :resource_id

      DynamicEnum :access_category_id
      DynamicEnum :normal_location_id, :null => false
      DynamicEnum :access_clearance_procedure_id
      DynamicEnum :accessioned_status_id
      String :agency_assigned_id
      String :approval_date
      DynamicEnum :colour_id
      DynamicEnum :contained_within_id
      TextField :description
      TextField :exhibition_history
      TextField :exhibition_notes
      Integer :exhibition_quality, :default => 0
      Integer :file_issue_allowed, :default => 1
      DynamicEnum :format_id, :null => false
      DynamicEnum :intended_use_id
      String :original_registration_date
      TextField :preferred_citation
      TextField :preservation_notes
      DynamicEnum :preservation_restriction_status_id, :null => false
      TextField :remark
      String :title
      DynamicEnum :salvage_priority_code_id
      Integer :publish

      apply_mtime_columns
    end

    alter_table(:digital_representation) do
      add_foreign_key([:repo_id], :repository, :key => :id)
      add_foreign_key([:archival_object_id], :archival_object, :key => :id)
      add_foreign_key([:resource_id], :resource, :key => :id)
    end

    create_enum('runcorn_digital_representation_contained_within', ['FIXME'])
    create_enum('runcorn_digital_preservation_restriction_status', ['FIXME'])

    alter_table(:representation_approved_by_rlshp) do
      add_column(:digital_representation_id, :integer,  :null => true)
      add_foreign_key([:digital_representation_id], :digital_representation, :key => :id)
    end

    alter_table(:deaccession) do
      add_column(:digital_representation_id, :integer,  :null => true)
      add_foreign_key([:digital_representation_id], :digital_representation, :key => :id, :name => 'deaccession_digrep_id_fk')
    end

    alter_table(:extent) do
      add_column(:digital_representation_id, :integer,  :null => true)
      add_foreign_key([:digital_representation_id], :digital_representation, :key => :id, :name => 'extent_digrep_id_fk')
    end

    alter_table(:external_id) do
      add_column(:digital_representation_id, :integer,  :null => true)
      add_foreign_key([:digital_representation_id], :digital_representation, :key => :id, :name => 'external_id_digrep_id_fk')
    end
  end

  down do
  end

end
