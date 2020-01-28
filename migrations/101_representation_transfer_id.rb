require 'db/migrations/utils'

Sequel.migration do
  up do
    alter_table(:physical_representation) do
      add_column(:transfer_id, Integer, :null => true)
    end
  end
end
