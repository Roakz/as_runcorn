require 'db/migrations/utils'

Sequel.migration do

  up do
    alter_table(:deaccession) do
      add_column(:archival_object_id, :integer,  :null => true)
      add_foreign_key([:archival_object_id], :archival_object, :key => :id, :name => 'deaccession_archobj_id_fk')
    end
  end

  down do
  end

end
