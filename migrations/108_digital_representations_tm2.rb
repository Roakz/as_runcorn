require 'db/migrations/utils'

Sequel.migration do

  up do

    alter_table(:digital_representation) do
      add_column(:previous_system_identifiers, String, :null => true)
      add_column(:image_resource_type_id, Integer, :null => true)
      add_foreign_key([:image_resource_type_id], :enumeration_value, :key => :id, :name => 'runcorn_image_resource_type_fk')
    end

    create_editable_enum('runcorn_image_resource_type',
      [
        'image',
        'text',
        'physical_object',
        'sound',
        'moving_image'
      ])
  end
end
