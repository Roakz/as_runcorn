require 'db/migrations/utils'

Sequel.migration do

  up do
    drop_table(:external_resource)
  end

end
