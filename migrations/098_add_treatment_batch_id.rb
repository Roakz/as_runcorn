require 'db/migrations/utils'

Sequel.migration do
  up do
    alter_table(:conservation_treatment) do
      add_column(:treatment_batch_id, String, :null => true)
      add_index([:treatment_batch_id], :name => "treatment_batch_id_idx")
    end
  end
end
