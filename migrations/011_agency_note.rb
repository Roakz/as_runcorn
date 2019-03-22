require 'db/migrations/utils'

Sequel.migration do

  up do
    alter_table(:agent_corporate_entity) do
      TextField :agency_note, :null => true
    end
  end

  down do
  end

end
