require 'db/migrations/utils'

Sequel.migration do

  up do
    alter_table(:archival_object) do
      add_index([:root_record_id, :id, :parent_id], :unique => false, :name => "ao_tree_structure_idx")
    end
  end

end
