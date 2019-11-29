require 'db/migrations/utils'

Sequel.migration do

  up do
    alter_table(:resource) do
      add_column(:retention_status_id, Integer, :null => true)
      add_foreign_key([:retention_status_id], :enumeration_value, :key => :id, :name => 'runcorn_retention_status_fk')
      set_column_type(:description, :text)
    end

    alter_table(:physical_representation) do
      drop_column(:access_category)
    end

    alter_table(:archival_object) do
      add_column(:original_registration_date, String, :null => true)
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
  end

end
