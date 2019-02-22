require 'db/migrations/utils'

Sequel.migration do

  up do
    alter_table(:agent_corporate_entity) do
      add_column(:registration_state, String, :default => 'draft')
    end
  end

  down do
  end

end
