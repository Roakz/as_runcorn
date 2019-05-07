require 'db/migrations/utils'

Sequel.migration do

  up do
    [:resource, :archival_object].each do |model|
      alter_table(model) do
        add_column(:disposal_class, String, :null => true)
      end
    end
  end

  down do
  end

end
