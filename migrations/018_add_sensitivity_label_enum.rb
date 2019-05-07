require 'db/migrations/utils'

Sequel.migration do

  up do

    [:resource, :archival_object].each do |model|
      alter_table(model) do
        add_column(:sensitivity_label_id, Integer, :null => true)
        add_foreign_key([:sensitivity_label_id], :enumeration_value, :key => :id, :name => "runcorn_#{model}_sensitivity_label_fk")
      end
    end

    create_editable_enum('runcorn_sensitivity_label',
                         [
                          'atsi_cultural',
                          'cultural_sensitivity',
                          'distressing',
                          'published',
                          'secret_and_sacred',
                         ])
  end

  down do
  end

end
