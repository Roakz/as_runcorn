require 'db/migrations/utils'

Sequel.migration do

  up do
    alter_table(:top_container) do
      add_column(:remarks, :text, :null => true)
    end
  end
end
