require 'db/migrations/utils'

Sequel.migration do

  up do
    # remove the value 'Approximate' from the date_certainty enum
    # point any refs to 'approximate' instead

    enum_id = self[:enumeration].filter(:name => 'date_certainty').get(:id)

    lcase_id = self[:enumeration_value].filter(:enumeration_id => enum_id, :value => 'approximate').get(:id)
    ucase_id = self[:enumeration_value].filter(:enumeration_id => enum_id, :value => 'Approximate').get(:id)

    self[:date].filter(:certainty_id => ucase_id).update(:certainty_id => lcase_id)
    self[:date].filter(:certainty_end_id => ucase_id).update(:certainty_end_id => lcase_id)

    self[:enumeration_value].filter(:id => ucase_id).delete
  end

  down do
  end

end
