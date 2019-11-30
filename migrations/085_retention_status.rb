require 'db/migrations/utils'

Sequel.migration do

  up do
    alter_table(:resource) do
      add_column(:retention_status_id, Integer, :null => true)
      add_foreign_key([:retention_status_id], :enumeration_value, :key => :id, :name => 'runcorn_retention_status_fk')
      set_column_type(:description, :text)
    end

    alter_table(:physical_representation) do
      drop_foreign_key(:access_category_id)
    end

    alter_table(:archival_object) do
      add_column(:original_registration_date, String, :null => true)
    end

    alter_table(:location) do
      add_column(:storage_type_id, Integer, :null => true)
      add_foreign_key([storage_type_id, :enumeration_value, :key => :id, :name => 'runcorn_storage_type_fk'])
    end

    create_enum('runcorn_retention_status', [
      'long_term_temporary',
      'mixed',
      'not_available',
      'permanent',
      'temporary',
      'unappraised',
      'unsentenced'
    ])

    create_enum('runcorn_storage_type', [
      'BAY',
      'BMS',
      'CAR',
      'DSH',
      'FLT',
      'HAN',
      'LDR',
      'LGP',
      'MDP',
      'MDR',
      'PDR',
      'SMP',
      'XLD',
      'CDRL',
      'CDRM',
      'CDRS',
      'HANG',
      'FDR',
      'NAA'
    ])
  end

end
