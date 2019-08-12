require 'db/migrations/utils'

Sequel.migration do

  up do
    alter_table(:rap) do
      add_column(:notice_date, String)
    end
  end

  down do
  end

end
