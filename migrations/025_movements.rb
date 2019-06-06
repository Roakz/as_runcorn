require 'db/migrations/utils'

Sequel.migration do

  up do
    create_table(:movement) do
      primary_key :id

      Integer :lock_version, :default => 0, :null => false
      Integer :json_schema_version, :null => false

      Integer :top_container_id, :null => true
      Integer :physical_representation_id, :null => true

      Integer :storage_location_id, :null => true
      DynamicEnum :functional_location_id, :null => true
      String :context_uri, :null => true
      String :user, :null => false

      DateTime :move_date, :null => false

      apply_mtime_columns
    end

    alter_table(:movement) do
      add_foreign_key([:top_container_id], :top_container, :key => :id)
      add_foreign_key([:physical_representation_id], :physical_representation, :key => :id)
      add_foreign_key([:storage_location_id], :location, :key => :id)
    end
  end

end
