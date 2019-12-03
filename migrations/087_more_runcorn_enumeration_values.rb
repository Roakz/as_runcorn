Sequel.migration do

  up do
    {
      'runcorn_format' => [
        'Architectural or technical drawing',
        'Chart (produced by machine)',
        'Film (roll)',
        'Photographic - Negative',
        'Photographic - Transparency',
        'Photographic - Glass Plate Negative',
        'Photographic - Slide',
        'Object',
        'Other',
      ],
      'runcorn_physical_representation_contained_within' => [
        'Box - Microfiche Box',
        'Core',
        'Encapsulate',
      ],
      'runcorn_digital_representation_contained_within' => [
        'Digital media - PC',
        'Digital media - Server',
        'Digital media - LTO computer tape',
        'Digital media - Floppy disc - 8"',
        'Digital media - Floppy disc - 3 1/2"',
        'Digital media - Floppy disc - 5 1/4"',
        'Digital media - Other',
      ]
    }.each do |enumeration_name, new_values|
      enumeration_id = self[:enumeration][:name => enumeration_name][:id]
      max_position = self[:enumeration_value].filter(:enumeration_id => enumeration_id).max(:position)

      new_values.each_with_index do |enumeration_value, idx|
        begin
          self[:enumeration_value]
            .insert(enumeration_id: enumeration_id,
                    value: enumeration_value,
                    position: max_position + 1 + idx)
        rescue
          $stderr.puts("Error inserting enum for #{enumeration_name} #{enumeration_value}: #{$!}")
        end
      end
    end
  end

end
