require 'db/migrations/utils'

Sequel.migration do

  up do
    alter_table(:digital_representation) do
      set_column_allow_null(:file_type_id)
    end
  end

end

