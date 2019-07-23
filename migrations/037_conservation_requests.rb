require 'db/migrations/utils'

Sequel.migration do

  up do
    create_table(:conservation_request) do
      primary_key :id
      apply_mtime_columns
    end

    create_table(:conservation_request_representations) do
      primary_key :id

      Integer :conservation_request_id, :null => false

      Integer :digital_representation_id
      Integer :physical_representation_id
    end

    alter_table(:conservation_request_representations) do
      add_foreign_key([:conservation_request_id], :conservation_request, :key => :id)
      add_foreign_key([:digital_representation_id], :digital_representation, :key => :id)
      add_foreign_key([:physical_representation_id], :physical_representation, :key => :id)
    end

  end

end
