require 'db/migrations/utils'

Sequel.migration do

  up do
    alter_table(:top_container) do
      add_column(:current_location_id, Integer, :null => true)
      add_foreign_key([:current_location_id], :enumeration_value, :key => :id, :name => "runcorn_top_container_current_location_fk")
    end

    enum_id = self[:enumeration].filter(:name => 'runcorn_location').get(:id)
    home_id = self[:enumeration_value].filter(:enumeration_id => enum_id, :value => 'HOME').get(:id)
    self[:top_container].update(:current_location_id => home_id)
  end

  down do
  end

end
