require 'db/migrations/utils'

Sequel.migration do

  up do
    alter_table(:physical_representation) do
      TextField :other_restrictions_notes, :null => true
      TextField :remarks, :null => true
    end
    alter_table(:digital_representation) do
      TextField :other_restrictions_notes, :null => true
      TextField :remarks, :null => true
    end
  end

  down do
  end

end
