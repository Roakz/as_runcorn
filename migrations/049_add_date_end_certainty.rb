require 'db/migrations/utils'

Sequel.migration do

  up do
    alter_table(:date) do
      add_column(:certainty_end, String, :null => true)
    end
  end

  down do
  end

end
