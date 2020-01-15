require 'db/migrations/utils'

Sequel.migration do

  up do
    alter_table(:digital_representation) do
      add_column(:archivist_approved, Integer, :null => false, :default => 0 )
    end
  end

end
