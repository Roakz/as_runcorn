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

      DynamicEnum :reason_requested_id, :null => false
      String :reason_requested_comments, :null => true
    end

    create_table(:conservation_request_representations) do
      primary_key :id

      Integer :conservation_request_id, :null => false

      Integer :digital_representation_id
      Integer :physical_representation_id
    end

    alter_table(:conservation_request_representations) do
      add_foreign_key([:conservation_request_id], :conservation_request, :key => :id)
      add_foreign_key([:digital_representation_id], :digital_representation, :key => :id)
      add_foreign_key([:physical_representation_id], :physical_representation, :key => :id)
    end

    create_editable_enum('conservation_request_reason',
                         [
                           'nefarious schemes',
                         ])
  end
end
