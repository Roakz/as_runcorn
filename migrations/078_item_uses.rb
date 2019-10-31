require 'db/migrations/utils'

Sequel.migration do

  up do
    create_table(:item_use) do
      primary_key :id

      Integer :lock_version, :default => 0, :null => false
      Integer :json_schema_version, :null => false

      Integer :repo_id, :null => false

      foreign_key :physical_representation_id, :physical_representation, :null => false
      String :use_identifier, :null => false

      String :item_use_type, :null => false
      String :status, :null => false
      String :used_by, :null => false
      String :start_date, :null => true
      String :end_date, :null => true

      apply_mtime_columns
    end

    alter_table(:item_use) do
      add_foreign_key([:repo_id], :repository, :key => :id)
      add_unique_constraint([:physical_representation_id, :use_identifier], :name => :item_use_uniq_prep_use_ident)
    end
  end

end
