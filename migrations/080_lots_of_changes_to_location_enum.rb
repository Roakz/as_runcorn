require 'db/migrations/utils'

Sequel.migration do

  up do
    enum_id = self[:enumeration].filter(:name => 'runcorn_location').get(:id)
    home_id = self[:enumeration_value].filter(:enumeration_id => enum_id, :value => 'HOME').get(:id)

    models = {
      :physical_representation => [:current_location_id, :normal_location_id],
      :digital_representation => [:normal_location_id],
      :top_container => [:current_location_id],
      :movement => [:functional_location_id],
    }

    # move refs to these to HOME and then delete them
    home_and_die = ['ATT', 'DIG', 'CAM', 'EXTWEB', 'FVT', 'MAP', 'VAULT1', 'VAULT2',
                    'MIC', 'N/A', 'REF', 'REF SCAN', 'REP', 'REP2', 'SCAN RR',
                    'SCAN PART', 'SCAN RR', 'SCANNED', 'SCANNED EX', 'Repository']

    home_and_die.each do |val|
      id = self[:enumeration_value].filter(:enumeration_id => enum_id, :value => val).get(:id)

      models.each do |model, cols|
        cols.each do |col|
          self[model].filter(col => id).update(col => home_id)
        end
      end

      self[:enumeration_value].filter(:id => id).delete
    end

    # move this one too
    # 'JOL' => 'OUT'
    id = self[:enumeration_value].filter(:enumeration_id => enum_id, :value => 'JOL').get(:id)
    out_id = self[:enumeration_value].filter(:enumeration_id => enum_id, :value => 'OUT').get(:id)
    models.each do |model, cols|
      cols.each do |col|
        self[model].filter(col => id).update(col => out_id)
      end
    end
    self[:enumeration_value].filter(:id => id).delete


    # add this one
    # 'TODESK'
    pos = self[:enumeration_value].filter(:enumeration_id => enum_id).max(:position) + 1

    self[:enumeration_value].insert({:enumeration_id => enum_id, :value => 'TODESK', :position => pos})

    # move 'HOME' to the top - I assert there is no position 1
    self[:enumeration_value].filter(:id => home_id).update(:position => 1)
  end

  down do
  end

end
