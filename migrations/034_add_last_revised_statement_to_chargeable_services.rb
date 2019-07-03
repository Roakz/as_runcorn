require 'db/migrations/utils'

Sequel.migration do

  up do
    alter_table(:chargeable_service) do
      add_column(:last_revised_statement, String)
    end
  end

  down do
  end

end
