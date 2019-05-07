require 'db/migrations/utils'

Sequel.migration do

  up do
    alter_table(:archival_object) do
      add_column(:disposal_class, String, :null => true)
    end
  end

  down do
  end

end
