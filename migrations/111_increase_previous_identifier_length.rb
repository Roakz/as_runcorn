require 'db/migrations/utils'

Sequel.migration do

  up do
    alter_table(:archival_object) do
      set_column_type :previous_system_identifiers, :varchar, :size => 2048, :null => true
    end

    alter_table(:physical_representation) do
      set_column_type :previous_system_identifiers, :varchar, :size => 2048, :null => true
    end

    alter_table(:digital_representation) do
      set_column_type :previous_system_identifiers, :varchar, :size => 2048, :null => true
    end
  end

  down do
  end

end
