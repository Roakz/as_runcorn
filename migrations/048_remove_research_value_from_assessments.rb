require 'db/migrations/utils'

Sequel.migration do

  up do
    defn_id = self[:assessment_attribute_definition].filter(:type => 'rating', :label => 'Research Value').get(:id)
    self[:assessment_attribute].filter(:assessment_attribute_definition_id => defn_id).delete
    self[:assessment_attribute_definition].filter(:id => defn_id).delete
  end

  down do
  end
end
