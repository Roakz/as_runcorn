require 'db/migrations/utils'

Sequel.migration do

  up do
    [:physical_representation, :digital_representation].each do |model|
      alter_table(model) do
        drop_foreign_key(:salvage_priority_code_id)
      end
    end

    [:archival_object, :physical_representation, :digital_representation].each do |model|
      alter_table(model) do
        add_column(:significance_id, :integer,  :null => true)
        add_foreign_key([:significance_id], :enumeration_value, :key => :id, :name => "runcorn_#{model}_significance_fk")
      end
    end

    create_enum('runcorn_significance',
                ['standard',
                 'high',
                 'iconic',
                 'memory_of_the_world',
                ])
  end

  down do
  end

end
