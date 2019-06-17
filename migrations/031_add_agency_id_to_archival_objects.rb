require 'db/migrations/utils'

Sequel.migration do

  up do
    alter_table(:archival_object) do
      add_column(:agency_assigned_id, String, :null => true)
    end
  end

end
