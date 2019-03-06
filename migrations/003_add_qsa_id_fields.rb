require 'db/migrations/utils'

Sequel.migration do

  up do
    [
     :resource,
     :archival_object,
     :digital_object,
     :function,
     :mandate,
     :accession,
     :agent_corporate_entity,
    ].each do |model|

      alter_table(model) do
        # temporarily allow null so we can set some values on existing rows
        add_column(:qsa_id, Integer, :index => true, :null => true)
      end

      seq = 0
      self[model].each do |obj|
        seq += 1
        self[model].filter(:id => obj[:id]).update(:qsa_id => seq)
      end

      alter_table(model) do
        set_column_not_null :qsa_id
      end

      self[:sequence].insert(:sequence_name => "QSA_ID_#{model.upcase}", :value => seq)
    end
  end

  down do
  end

end
