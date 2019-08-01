require 'db/migrations/utils'

Sequel.migration do

  up do
    std_sig_id = self[:enumeration_value]
                   .filter(:enumeration_id => self[:enumeration].filter(:name => 'runcorn_significance').get(:id))
                   .filter(:value => 'standard').get(:id)

    [:archival_object, :physical_representation, :digital_representation].each do |model|
      self[model].update(:significance_id => std_sig_id)
    end
  end

  down do
  end

end
