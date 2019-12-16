require 'db/migrations/utils'

Sequel.migration do

  up do
    alter_table(:physical_representation) do
      set_column_type :title, :varchar, :size=>8192, :null => true
    end
    alter_table(:digital_representation) do
      set_column_type :title, :varchar, :size=>8192, :null => true
    end
  end

  down do
  end

end
