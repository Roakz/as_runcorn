require 'db/migrations/utils'

Sequel.migration do

  up do
    alter_table(:digital_representation) do
      drop_foreign_key(:normal_location_id)
    end

    alter_table(:physical_representation) do
      drop_foreign_key(:normal_location_id)
    end
  end

end
