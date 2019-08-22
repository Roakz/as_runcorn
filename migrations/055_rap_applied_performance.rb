require 'db/migrations/utils'

Sequel.migration do

  up do
    alter_table(:rap_applied) do
      add_column(:root_record_id, Integer, :null => true)
      add_index([:root_record_id, :is_active], :unique => false, :name => "rap_root_record_active_idx")
    end
  end

end
