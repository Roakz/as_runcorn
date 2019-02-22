require 'db/migrations/utils'

Sequel.migration do

  up do
    alter_table(:agent_corporate_entity) do
      add_column(:draft, :integer, :default => 1)
    end
  end

  down do
  end

end
