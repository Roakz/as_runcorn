require 'db/migrations/utils'

Sequel.migration do

  up do
    alter_table(:representation_approved_by_rlshp) do
      add_column(:resource_id, :integer,  :null => true)
      add_column(:archival_object_id, :integer,  :null => true)
      add_foreign_key([:resource_id], :resource, :key => :id)
      add_foreign_key([:archival_object_id], :archival_object, :key => :id)
    end

    alter_table(:resource) do
      add_column(:approval_date, String, :null => true)
    end

    alter_table(:archival_object) do
      add_column(:approval_date, String, :null => true)
    end
  end

  down do
  end

end
