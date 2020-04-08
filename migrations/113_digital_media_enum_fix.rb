require 'db/migrations/utils'

Sequel.migration do
  up do
    self.transaction do
      if digital_enum = self[:enumeration][:name => 'runcorn_digital_representation_contained_within']
        enum_id = digital_enum[:id]

        old_enum_value_id = self[:enumeration_value][:enumeration_id => enum_id, :value => 'Digital Media - Other'][:id] rescue nil
        new_enum_value_id = self[:enumeration_value][:enumeration_id => enum_id, :value => 'Digital media - Other'][:id] rescue nil

        if old_enum_value_id && !new_enum_value_id
          self[:enumeration_value].filter(:id => old_enum_value_id).update(:value => 'Digital media - Other')
        elsif old_enum_value_id && new_enum_value_id
          self[:digital_representation].filter(:contained_within_id => old_enum_value_id).update(:contained_within_id => new_enum_value_id)
          self[:enumeration_value].filter(:id => old_enum_value_id).delete
        end
      end
    end
  end
end
