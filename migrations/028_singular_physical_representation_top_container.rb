require 'db/migrations/utils'

Sequel.migration do

  up do
    alter_table(:sub_container) do
      drop_constraint(:sub_container_physrep_id_fk, :type => :foreign_key)
      drop_column(:physical_representation_id)
    end

    create_table(:representation_container_rlshp) do
      primary_key :id

      Integer :physical_representation_id
      Integer :top_container_id
      Integer :aspace_relationship_position

      apply_mtime_columns(false)
    end

    alter_table(:representation_container_rlshp) do
      add_foreign_key([:physical_representation_id], :physical_representation, :key => :id)
      add_foreign_key([:top_container_id], :top_container, :key => :id)
    end
  end

end
