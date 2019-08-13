require 'db/migrations/utils'

Sequel.migration do

  up do
    alter_table(:conservation_request) do
      drop_column(:reason_requested_comments)
      add_column(*ColumnDefs.textField(:reason_requested_comments))
    end

  end

end
