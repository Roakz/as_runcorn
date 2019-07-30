require 'db/migrations/utils'

Sequel.migration do

  up do
    alter_table(:physical_representation) do
      add_column(:monetary_value, String)
      add_column(*ColumnDefs.textField(:monetary_value_note))
    end
  end

  down do
  end

end
