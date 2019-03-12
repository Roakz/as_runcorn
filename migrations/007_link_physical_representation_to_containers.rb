require 'db/migrations/utils'

Sequel.migration do

  up do
    alter_table(:sub_container) do
      add_column(:physical_representation_id, :integer,  :null => true)
      add_foreign_key([:physical_representation_id], :physical_representation, :key => :id, :name => 'sub_container_physrep_id_fk')
    end
  end

  down do
  end

end
