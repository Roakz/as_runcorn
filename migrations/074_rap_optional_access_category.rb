require 'db/migrations/utils'

Sequel.migration do

  up do
    alter_table(:rap) do
      set_column_allow_null(:access_category_id)
    end
  end

end
