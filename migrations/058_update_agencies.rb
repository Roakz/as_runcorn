require 'db/migrations/utils'

Sequel.migration do

  up do
    alter_table(:agent_contact) do
      add_column(:position, String, :null => true)
    end
  end

  down do
  end

end
