require 'db/migrations/utils'

Sequel.migration do

  up do
    alter_table(:archival_object) do
      add_column(:transfer_id, Integer, :null => true)
    end
  end

  down do
  end

end
