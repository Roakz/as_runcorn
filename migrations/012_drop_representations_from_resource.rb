require 'db/migrations/utils'

Sequel.migration do

  up do
    [
      :physical_representation,
      :digital_representation,
    ].each do |representation_table|
      self[representation_table].filter(Sequel.~(:resource_id => nil)).delete
      alter_table(representation_table) do
        drop_foreign_key :resource_id
      end
    end
  end

  down do
  end

end
