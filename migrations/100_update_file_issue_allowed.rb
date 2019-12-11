Sequel.migration do

  up do
    enum_id = self[:enumeration].filter(:name => 'runcorn_file_issue_allowed').get(:id)
    true_id = self[:enumeration_value].filter(:enumeration_id => enum_id, :value => 'allowed_true').get(:id)
    false_id = self[:enumeration_value].filter(:enumeration_id => enum_id, :value => 'allowed_true').get(:id)

    ['digital', 'physical'].each do |table|
      alter_table("#{table}_representation".intern) do
        add_column(:file_issue_allowed_id, Integer, :null => false)
        add_foreign_key([:file_issue_allowed_id], :enumeration_value, :key => :id, :name => "runcorn_file_issue_allowed_#{table}_fk")
      end

      self["#{table}_representation".intern]
          .filter(:file_issue_allowed => 1)
          .update(:file_issue_allowed_id => true_id)

      self["#{table}_representation".intern]
          .filter(:file_issue_allowed => 0)
          .update(:file_issue_allowed_id => false_id)

      alter_table("#{table}_representation".intern) do
        drop_column(:file_issue_allowed)
      end
    end

    create_enum('runcorn_file_issue_allowed', ['allowed_true', 'allowed_false', 'allowed_contact_qsa'])
  end
end