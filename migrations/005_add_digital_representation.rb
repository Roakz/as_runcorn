require 'db/migrations/utils'

Sequel.migration do

  up do
    create_editable_enum('runcorn_digital_file_type', ['JPEG', 'TIFF', 'PDF'])

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
      DynamicEnum :contained_within_id, :null => false
      TextField :description
      TextField :exhibition_history
      TextField :exhibition_notes
      Integer :exhibition_quality, :default => 0
      Integer :file_issue_allowed, :default => 1
      String :file_size
      DynamicEnum :file_type_id, :null => false,
      DynamicEnum :intended_use_id
      String :original_registration_date
      TextField :preferred_citation
      TextField :preservation_notes
      DynamicEnum :preservation_priority_rating_id
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

    create_editable_enum('runcorn_digital_representation_contained_within',
                         [
                           "Compact Disc (CD)",
                           "Digital Versatile Disc (DVD)",
                           "External Hard Disk Drive (HDD)",
                           "Floppy Disk",
                           "Network Attached Storage (NAS)",
                           "Portable Universal Serial Bus (USB)",
                         ])

    alter_table(:representation_approved_by_rlshp) do
      add_column(:digital_representation_id, :integer,  :null => true)
      add_foreign_key([:digital_representation_id], :digital_representation, :key => :id)
    end

    alter_table(:deaccession) do
      add_column(:digital_representation_id, :integer,  :null => true)
      add_foreign_key([:digital_representation_id], :digital_representation, :key => :id, :name => 'deaccession_digrep_id_fk')
    end

    alter_table(:external_id) do
      add_column(:digital_representation_id, :integer,  :null => true)
      add_foreign_key([:digital_representation_id], :digital_representation, :key => :id, :name => 'external_id_digrep_id_fk')
    end
  end

  down do
  end

end
