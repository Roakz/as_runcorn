require 'db/migrations/utils'

Sequel.migration do

  up do
    # Target availabilities:
    # 1. [available] Available. There are no other restrictions current.
    # 2. [unavailable_temporarily] Temporarily Unavailable. Contact QSA for more information.
    # 3. [unavailable_due_to_conservation] This item must be assessed by a conservator to determine if it can be made available.
    # 4. [unavailable_due_to_condition] This item is unavailable due to its condition. Where possible, a copy will be made available.
    # 5. [unavailable_due_to_format] This item is unavailable due to its format. Where possible, a copy will be made available.
    # 6. [unavailable_due_to_deaccession] This item is unavailable because it has been deaccessioned or destroyed.
    # 7. [unavailable_due_to_date_range] As the date range of this item is uncertain, contact QSA to confirm availability.
    # 8. [unavailable_contact_qsa] Availability needs to be determined by an archivist. Contact QSA for more information.

    enumeration_id = self[:enumeration][:name => 'runcorn_physical_representation_availability'][:id]
    max_position = self[:enumeration_value].filter(:enumeration_id => enumeration_id).max(:position)

    self[:enumeration_value]
      .insert(:enumeration_id => enumeration_id,
              :value => 'unavailable_due_to_date_range',
              :position => max_position + 1)

    self[:enumeration_value]
      .insert(:enumeration_id => enumeration_id,
              :value => 'unavailable_contact_qsa',
              :position => max_position + 2)
  end

end
