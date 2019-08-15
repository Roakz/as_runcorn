require 'db/migrations/utils'

Sequel.migration do

  up do
    alter_table(:rap_applied) do
      drop_column(:version)
    end
  end

  down do
  end

end
