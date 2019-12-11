Sequel.migration do

  up do
    alter_table(:physical_representation) do
      drop_column(:file_issue_allowed)
      add_column(:file_issue_allowed_id, Integer, :null => true)
      add_foreign_key([:file_issue_allowed_id], :enumeration_value, :key => :id, :name => 'runcorn_file_issue_allowed_physical_fk')
    end

    alter_table(:digital_representation) do
      drop_column(:file_issue_allowed)
      add_column(:file_issue_allowed_id, Integer, :null => true)
      add_foreign_key([:file_issue_allowed_id], :enumeration_value, :key => :id, :name => 'runcorn_file_issue_allowed_digital_fk')
    end

    create_enum('runcorn_file_issue_allowed', ['allowed_true', 'allowed_false', 'allowed_contact_qsa'])
  end
end