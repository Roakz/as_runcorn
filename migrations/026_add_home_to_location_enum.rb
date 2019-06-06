require 'db/migrations/utils'

Sequel.migration do

  up do
    enum_id = self[:enumeration].filter(:name => 'runcorn_location').get(:id)

    pos = self[:enumeration_value].filter(:enumeration_id => enum_id).max(:position) + 1

    self[:enumeration_value].insert({:enumeration_id => enum_id, :value => 'HOME', :position => pos})
  end

  down do
  end

end
