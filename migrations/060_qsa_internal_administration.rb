require 'db/migrations/utils'

Sequel.migration do

  up do
    alter_table(:agent_corporate_entity) do
      add_column(:original_registration_date, String, :null => true)
    end
  end

  down do
  end

end
