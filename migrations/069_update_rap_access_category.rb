require 'db/migrations/utils'

Sequel.migration do

  up do
    runcorn_rap_access_category_enum_id = self[:enumeration].filter(:name => 'runcorn_rap_access_category').select(:id)

    # Move some enums to make way for the new one
    self[:enumeration_value]
      .filter(:enumeration_id => runcorn_rap_access_category_enum_id)
      .filter(:position => 12)
      .update(:position => 13)

    self[:enumeration_value]
      .filter(:enumeration_id => runcorn_rap_access_category_enum_id)
      .filter(:position => 11)
      .update(:position => 12)

    self[:enumeration_value]
      .filter(:enumeration_id => runcorn_rap_access_category_enum_id)
      .filter(:position => 10)
      .update(:position => 11)

    self[:enumeration_value].insert(:enumeration_id => runcorn_rap_access_category_enum_id,
                                    :value => 'Overriding Legislation - Child Protection Act 1999',
                                    :position => 10)
  end

  down do
  end

end
