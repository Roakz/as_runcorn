require 'db/migrations/utils'

Sequel.migration do

  up do
    alter_table(:rap) do
      drop_column(:change_description)
      drop_column(:authorised_by)
      drop_column(:change_date)
      drop_column(:approved_by)
    end
  end

end
