require 'db/migrations/utils'

Sequel.migration do

  up do

    create_table(:conservation_treatment_assessment_rlshp) do
      primary_key :id

      Integer :conservation_treatment_id
      Integer :assessment_id

      Integer :suppressed, :default => 0
      Integer :aspace_relationship_position

      apply_mtime_columns(false)
    end

    alter_table(:conservation_treatment_assessment_rlshp) do
      add_foreign_key([:conservation_treatment_id], :conservation_treatment, :key => :id)
      add_foreign_key([:assessment_id], :assessment, :key => :id)
    end

  end
end
