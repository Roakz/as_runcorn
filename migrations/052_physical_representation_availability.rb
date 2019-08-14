require 'db/migrations/utils'

Sequel.migration do

  up do
    alter_table(:physical_representation) do
      add_column(:availability_id, :integer,  :null => true)
      add_foreign_key([:availability_id], :enumeration_value, :key => :id, :name => "runcorn_physical_representation_availability")
    end

    create_enum('runcorn_physical_representation_availability', [
      'available',
      'unavailable_temporarily',
      'unavailable_due_to_conservation',
      'unavailable_due_to_condition',
      'unavailable_due_to_format',
      'unavailable_due_to_deaccession',
    ])
  end

  down do
  end

end
