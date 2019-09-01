require 'db/migrations/utils'

Sequel.migration do

  up do
    alter_table(:resource) do
      add_column(:archivist_approved, Integer, :null => true)
      add_column(:copyright_status_id, Integer, :null => true)
      add_foreign_key([:copyright_status_id], :enumeration_value, :key => :id, :name => 'runcorn_copyright_status_fk')
      add_column(:serialised, Integer, :null => true)
      add_column(:original_registration_date, String, :null => true)
      add_column(:information_sources, String, :null => true)
      add_column(:abstract, String, :null => true)
      add_column(:description, String, :null => true)
    end

    create_enum('runcorn_copyright_status', [
      'copyright_expired',
      'copyright_state_of_queensland'
    ])
  end

  down do
  end

end
