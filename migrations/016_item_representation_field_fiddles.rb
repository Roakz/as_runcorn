require 'db/migrations/utils'

Sequel.migration do

  up do
    alter_table(:archival_object) do
      add_column(*ColumnDefs.textField(:description))
      add_column(:access_clearance_procedure_id, Integer, :null => true)
      add_foreign_key([:access_clearance_procedure_id], :enumeration_value, :key => :id, :name => 'access_clearance_procedure_fk')
    end

    alter_table(:physical_representation) do
      self[:physical_representation].filter(Sequel.~(:access_clearance_procedure_id => nil)).delete
      drop_foreign_key(:access_clearance_procedure_id)
    end

    alter_table(:digital_representation) do
      self[:digital_representation].filter(Sequel.~(:access_clearance_procedure_id => nil)).delete
      drop_foreign_key(:access_clearance_procedure_id)
    end
  end

  down do
  end

end
