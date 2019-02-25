require 'db/migrations/utils'

Sequel.migration do

  up do
    alter_table(:agent_corporate_entity) do
      add_column(:registration_state, String, :default => 'draft')
      add_column(:registration_last_action, String)
      add_column(:registration_last_user, String)
      add_column(:registration_last_time, DateTime, :index => true)
    end

    # assume extant agencies have been approved
    self[:agent_corporate_entity].update(:registration_state => 'approved')
  end

  down do
  end

end
