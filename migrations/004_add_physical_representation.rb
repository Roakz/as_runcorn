require 'db/migrations/utils'

Sequel.migration do

  up do
    create_table(:physical_representation) do
      primary_key :id
      Integer :lock_version, :default => 0, :null => false

      Integer :repo_id, :null => false
      TextField :description

      Integer :archival_object_id
      Integer :resource_id

      apply_mtime_columns
    end

    alter_table(:physical_representation) do
      add_foreign_key([:repo_id], :repository, :key => :id)
      add_foreign_key([:archival_object_id], :archival_object, :key => :id)
      add_foreign_key([:resource_id], :resource, :key => :id)
    end
  end

  down do
  end

end
