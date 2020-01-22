require 'db/migrations/utils'

Sequel.migration do
  up do
    alter_table(:item_use) do
      set_column_allow_null(:physical_representation_id)
      add_column(:digital_representation_id, Integer, :null => true)
      add_foreign_key([:digital_representation_id], :digital_representation, :key => :id)
    end
  end
end
