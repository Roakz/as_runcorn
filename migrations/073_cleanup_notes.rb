require 'db/migrations/utils'

Sequel.migration do

  up do
    # QSA has a customisation that only note_singlepart is supported for Agents
    # and the type enumeration has been customised also
    #
    # Drop all agent or singlepart notes so we can create only the pure notes
    # we desire
    note_ids =  self[:note]
                  .filter(Sequel.|(Sequel.~(:agent_person_id => nil),
                                   Sequel.~(:agent_corporate_entity_id => nil),
                                   Sequel.~(:agent_family_id => nil),
                                   Sequel.~(:agent_software_id => nil),
                                   Sequel.like(:notes, '{"jsonmodel_type":"note_singlepart"%')))
                  .select(:id)
                  .map {|row| row[:id]}

    self[:note_persistent_id]
      .filter(:note_id => note_ids)
      .delete

    self[:subnote_metadata]
      .filter(:note_id => note_ids)
      .delete

    self[:note]
      .filter(:id => note_ids)
      .delete
  end

  down do
  end

end
