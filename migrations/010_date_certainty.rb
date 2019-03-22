require 'db/migrations/utils'

Sequel.migration do

  up do
    # Remove all date certainty values except "approximate"
    certainty_enum_id = self[:enumeration][:name => 'date_certainty'][:id] or die

    self[:enumeration_value]
      .filter(:enumeration_id => certainty_enum_id)
      .filter(Sequel.~(:value => 'approximate'))
      .delete
  end

  down do
  end

end
