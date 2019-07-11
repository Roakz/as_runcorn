require 'db/migrations/utils'

Sequel.migration do

  up do
    create_table(:rap) do
      primary_key :id

      Integer :lock_version, :default => 0, :null => false
      Integer :json_schema_version, :null => false

      Integer :open_access_metadata, :default => 0, :null => false
      DynamicEnum :access_status_id, :null => false
      DynamicEnum :access_category_id, :null => false

      String :period, :null => false

      apply_mtime_columns
    end

    create_table(:rap_rlshp) do
      primary_key :id

      Integer :rap_id
      Integer :archival_object_id
      Integer :digital_representation_id
      Integer :physical_representation_id
      Integer :aspace_relationship_position

      TextField :change_description
      String :authorised_by
      String :change_date
      String :approved_by
      String :internal_reference

      apply_mtime_columns(false)
    end

    alter_table(:rap_rlshp) do
      add_foreign_key([:rap_id], :rap, :key => :id)
      add_foreign_key([:archival_object_id], :archival_object, :key => :id)
      add_foreign_key([:digital_representation_id], :digital_representation, :key => :id)
      add_foreign_key([:physical_representation_id], :physical_representation, :key => :id)
    end

    create_enum('runcorn_rap_access_status', [
      'Restricted Access',
      'Open Access',
    ])

    create_enum('runcorn_rap_access_category', [
      'All public records',
      'Personal affairs of an individual',
      'Information subject to legal Professional Privilege',
      'Information whose disclosure would be found to be a breach of confidence',
      'National or State Security Information',
      'Law enforcement or public safety information',
      'Cabinet matters',
      'Executive Council information and ministerial records',
      'Overriding Legislation',
      'Non-Publication Order',
      'Sealed by Court12.',
      'N/A',
    ])
  end

  down do
  end

end
