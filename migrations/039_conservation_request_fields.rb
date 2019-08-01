require 'db/migrations/utils'

Sequel.migration do

  up do
    # Supersede migration 037
    drop_table(:conservation_request_representations)
    drop_table(:conservation_request)

    create_table(:conservation_request) do
      primary_key :id
      apply_mtime_columns

      Integer :lock_version, :default => 0, :null => false
      Integer :repo_id, :null => false

      String :date_of_request, :null => false
      String :date_required_by, :null => true
      String :requested_by, :null => false

      DynamicEnum :requested_for_id, :null => false
      DynamicEnum :reason_requested_id, :null => false
      DynamicEnum :client_type_id, :null => false
      DynamicEnum :status_id, :null => false

      String :reason_requested_comments, :null => true

      String :client_name, :null => true
      String :client_id, :null => true
    end

    create_table(:conservation_request_representations) do
      primary_key :id

      Integer :conservation_request_id, :null => false

      Integer :physical_representation_id
    end

    alter_table(:conservation_request_representations) do
      add_foreign_key([:conservation_request_id], :conservation_request, :key => :id)
      add_foreign_key([:physical_representation_id], :physical_representation, :key => :id)
    end


    create_table(:conservation_request_assessment_rlshp) do
      primary_key :id

      Integer :conservation_request_id
      Integer :assessment_id

      Integer :suppressed, :default => 0
      Integer :aspace_relationship_position

      apply_mtime_columns(false)
    end

    alter_table(:conservation_request_assessment_rlshp) do
      add_foreign_key([:conservation_request_id], :conservation_request, :key => :id)
      add_foreign_key([:assessment_id], :assessment, :key => :id)
    end


    create_editable_enum('conservation_request_requested_for',
                         [
                           'Public Access',
                           'Agency Access',
                           'Exhibition',
                           'Loan',
                           'Digitisation',
                           'Transfer',
                           'Storage',
                           'Significance',
                           'Preservation Project',
                           'Other',
                         ])


    create_editable_enum('conservation_request_reason',
                         [
                           'Condition',
                           'Mould',
                           'WH&S',
                           'Separation',
                           'Copy Press',
                           'Pest Damage',
                           'Rehousing',
                           'Other',
                         ])

    create_editable_enum('conservation_request_client_type',
                         [
                           'Internal',
                           'External',
                         ])

    create_enum('conservation_request_status',
                [
                  'Draft',
                  'Ready For Review',
                  'Cancelled',
                  'Assessment Created',
                ])

  end
end
