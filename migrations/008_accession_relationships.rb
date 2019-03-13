require 'db/migrations/utils'

Sequel.migration do

  up do
    create_table(:representation_accession_rlshp) do
      primary_key :id
      Integer :physical_representation_id
      Integer :digital_representation_id
      Integer :accession_id
      Integer :aspace_relationship_position

      apply_mtime_columns(false)
    end

    alter_table(:representation_accession_rlshp) do
      add_foreign_key([:physical_representation_id], :physical_representation, :key => :id)
      add_foreign_key([:digital_representation_id], :digital_representation, :key => :id)
      add_foreign_key([:accession_id], :accession, :key => :id)
    end
  end

  down do
  end

end
