require 'db/migrations/utils'

Sequel.migration do

  up do
    # Replace runcorn_rap_access_category enum  'Overriding Legislation' with: 
    # * Overriding Legislation - Births, Deaths and Marriages Registration Act 2003
    # * Overriding Legislation - Adoption Act 2009
    runcorn_rap_access_category_enum_id = self[:enumeration].filter(:name => 'runcorn_rap_access_category').select(:id)
    self[:enumeration_value]
      .filter(:enumeration_id => runcorn_rap_access_category_enum_id)
      .filter(:value => 'Overriding Legislation')
      .update(:value => 'Overriding Legislation - Births, Deaths and Marriages Registration Act 2003')

    # Move some enums to make way for the new one
    self[:enumeration_value]
      .filter(:enumeration_id => runcorn_rap_access_category_enum_id)
      .filter(:position => 11)
      .update(:position => 12)

    self[:enumeration_value]
      .filter(:enumeration_id => runcorn_rap_access_category_enum_id)
      .filter(:position => 10)
      .update(:position => 11)

    self[:enumeration_value]
      .filter(:enumeration_id => runcorn_rap_access_category_enum_id)
      .filter(:position => 9)
      .update(:position => 10)

    self[:enumeration_value].insert(:enumeration_id => runcorn_rap_access_category_enum_id,
                                    :value => 'Overriding Legislation - Adoption Act 2009',
                                    :position => 9)

    # Fix runcorn_rap_access_category enum typo:
    #  * Sealed by Court12.
    self[:enumeration_value]
      .filter(:enumeration_id => runcorn_rap_access_category_enum_id)
      .filter(:value => 'Sealed by Court12.')
      .update(:value => 'Sealed by Court')
  end

  down do
  end

end
