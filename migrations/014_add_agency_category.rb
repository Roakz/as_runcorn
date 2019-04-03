require 'db/migrations/utils'

Sequel.migration do

  up do

    # supporting running this after the now removed version of this has run from series_system
    unless self[:agent_corporate_entity].columns.include?(:agency_category_id)
      alter_table(:agent_corporate_entity) do
        add_column(:agency_category_id, Integer, :null => true)
        add_foreign_key([:agency_category_id], :enumeration_value, :key => :id, :name => 'agency_category_fk')
      end

      create_editable_enum('agency_category',
                           [
                            'BUSU',
                            'COI',
                            'COM',
                            'COR',
                            'CRT',
                            'CWLTH',
                            'DEPT',
                            'DST',
                            'EDF',
                            'EXEC',
                            'FIRM',
                            'GOC',
                            'GOV',
                            'LAN',
                            'LEESA',
                            'LOC',
                            'MAG',
                            'MIN',
                            'NPA',
                            'NSW',
                            'OTHER',
                            'REG',
                            'RES',
                            'STAT',
                            'SUP',
                            'TRB',
                            'UNP',
                           ])
    end
  end

  down do
  end

end
