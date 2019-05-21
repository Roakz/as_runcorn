require 'db/migrations/utils'

Sequel.migration do

  up do
    alter_table(:physical_representation) do
      TextField :processing_handling_notes, :null => true
    end

    alter_table(:digital_representation) do
      TextField :processing_handling_notes, :null => true
    end
  end

  down do
  end

end
