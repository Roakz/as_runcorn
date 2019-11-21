require 'db/migrations/utils'

Sequel.migration do

  up do
    alter_table(:rap) do
      add_column(:years_default_applied, Integer, :null => false, :default => 0)
    end
  end

  down do
  end

end
