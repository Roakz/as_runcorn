require 'db/migrations/utils'

Sequel.migration do

  up do
    alter_table(:rap_applied) do
      add_column(:archival_object_id, Integer, :null => true)
      add_foreign_key([:archival_object_id], :archival_object, :key => :id)
    end
  end

end
