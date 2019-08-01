require 'db/migrations/utils'

Sequel.migration do

  up do
    [:archival_object, :physical_representation, :digital_representation].each do |model|
      alter_table(model) do
        add_column(:significance_is_sticky, :integer, :default => 0)
      end
    end
  end

  down do
  end

end
