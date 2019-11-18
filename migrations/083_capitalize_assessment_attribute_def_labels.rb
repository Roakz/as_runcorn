require 'db/migrations/utils'

Sequel.migration do

  up do
    self[:assessment_attribute_definition].each do |defn|
      self[:assessment_attribute_definition].filter(:id => defn[:id]).update(:label => defn[:label].capitalize)
    end
  end

  down do
  end

end
