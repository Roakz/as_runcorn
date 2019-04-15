require 'db/migrations/utils'

Sequel.migration do

  up do
    create_table(:agency_ancestor) do
      primary_key :id

      Integer :agent_corporate_entity_id, :null => false
      Integer :ancestor_id, :null => false
      String :subgraph_id, :null => false, :unique => false
    end

    alter_table(:agency_ancestor) do
      add_foreign_key([:agent_corporate_entity_id], :agent_corporate_entity, :key => :id)
      add_foreign_key([:ancestor_id], :agent_corporate_entity, :key => :id)
    end
  end

end
