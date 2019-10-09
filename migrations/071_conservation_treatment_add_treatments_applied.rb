require 'db/migrations/utils'

Sequel.migration do
  up do
    alter_table(:conservation_treatment) do
      add_column(*ColumnDefs.textField(:treatments_applied))
    end
  end
end
