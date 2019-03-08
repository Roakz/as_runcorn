require 'db/migrations/utils'

Sequel.migration do

  up do
    [
     :physical_representation,
     :digital_representation,
    ].each do |model|

      alter_table(model) do
        add_column(:qsa_id, Integer, :index => true, :null => true)
      end

      seq = 0
      self[model].each do |obj|
        seq += 1
        self[model].filter(:id => obj[:id]).update(:qsa_id => seq)
      end

      self[:sequence].insert(:sequence_name => "QSA_ID_#{model.upcase}", :value => seq)
    end
  end

  down do
  end

end
