require 'db/migrations/utils'

Sequel.migration do

  up do
    alter_table(:agent_person) do
      add_column(:previous_system_identifiers, String, :null => true)
      add_index([:previous_system_identifiers], :name => 'agent_person_prev_id_idx')
    end
  end

end
