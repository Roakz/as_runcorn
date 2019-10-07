require 'db/migrations/utils'

Sequel.migration do

  up do
    alter_table(:batch_action) do
      add_column(*ColumnDefs.textField(:last_report))
    end
  end

end
