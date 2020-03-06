require 'db/migrations/utils'

Sequel.migration do

  up do
    alter_table(:resource) do
      set_column_type(:information_sources, :text)
    end

    alter_table(:date) do
      set_column_type(:date_notes, :text)
    end

    alter_table(:archival_object) do
      add_column(:accessioned_status_id, Integer, :null => true)
      add_foreign_key([:accessioned_status_id], :enumeration_value, :key => :id, :name => 'runcorn_archival_object_accessioned_status_fk')
      add_column(:copyright_status_id, Integer, :null => true)
      add_foreign_key([:copyright_status_id], :enumeration_value, :key => :id, :name => 'runcorn_archival_object_copyright_status_fk')
      add_column(:previous_system_identifiers, String, :null => true)
      add_column(:archivist_approved, Integer, :null => true)
    end

    alter_table(:physical_representation) do
      add_column(:previous_system_identifiers, String, :null => true)
      add_column(:archivist_approved, Integer, :null => true)
    end

    # Let's redo note types
    create_enum('runcorn_note_singlepart_type', [
      'remarks',
      'description',
      'agency_control_number',
      'preferred_citation',
      'archivists_notes',
      'system_of_arrangement',
      'other_restrictions',
      'legacy_metadata_item',
      'legacy_metadata_image',
      'legacy_metadata_agency',
      'legacy_metadata_series',
      'information_sources',
      'legislation_establish',
      'legislation_abolish',
      'legislation_administered',
      'how_to_use',
      'general'
    ])
  end

  down do
  end

end
