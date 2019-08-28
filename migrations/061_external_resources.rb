require 'db/migrations/utils'

Sequel.migration do

  up do
    create_table(:external_resource) do
      primary_key :id

      String :title
      String :location
      Integer :publish
      Integer :agent_corporate_entity_id

      apply_mtime_columns
    end

    alter_table(:external_resource) do
      add_foreign_key([:agent_corporate_entity_id], :agent_corporate_entity, :key => :id)
    end
  end

  down do
  end

end
