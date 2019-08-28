require 'db/migrations/utils'

Sequel.migration do

  up do
    alter_table(:date) do
      add_column(:certainty_end_id, Integer, :null => true)
      add_foreign_key([:certainty_end_id], :enumeration_value, :key => :id, :name => 'end_certainty_fk')
    end
  end

  down do
  end

end
