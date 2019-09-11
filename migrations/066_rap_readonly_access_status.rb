require 'db/migrations/utils'

Sequel.migration do

  up do
    alter_table(:rap) do
      drop_foreign_key :access_status_id
    end

    access_status_enum_id = self[:enumeration].filter(:name => 'runcorn_rap_access_status').select(:id).first[:id]

    self[:enumeration_value]
      .filter(:enumeration_id => access_status_enum_id)
      .delete

    self[:enumeration]
      .filter(:id => access_status_enum_id)
      .delete
  end

end
