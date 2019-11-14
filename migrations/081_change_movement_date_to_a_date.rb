require 'db/migrations/utils'

Sequel.migration do

  up do
    alter_table(:movement) do
      set_column_type :move_date, :date
    end
  end

  down do
  end

end
