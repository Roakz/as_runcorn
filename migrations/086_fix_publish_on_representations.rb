require 'db/migrations/utils'

Sequel.migration do

  up do
    self[:physical_representation].filter(:publish => nil).update(:publish => 0)
    self[:digital_representation].filter(:publish => nil).update(:publish => 0)

    alter_table(:physical_representation) do
      set_column_not_null(:publish)
      set_column_default(:publish, 0)
    end

    alter_table(:digital_representation) do
      set_column_not_null(:publish)
      set_column_default(:publish, 0)
    end
  end

end
