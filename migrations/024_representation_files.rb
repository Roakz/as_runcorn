require 'db/migrations/utils'

Sequel.migration do

  up do

    create_table(:representation_file) do
      primary_key :id

      Integer :lock_version, :default => 0, :null => false
      Integer :json_schema_version, :null => false

      Integer :digital_representation_id, :null => false

      String :key, :null => false
      String :mime_type, :null => false

      apply_mtime_columns
    end

  end

end
