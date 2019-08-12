require 'db/migrations/utils'

Sequel.migration do

  up do
    alter_table(:rap) do
      set_column_allow_null(:years)
    end

    self[:rap]
      .filter(Sequel.~(:default_for_repo_id => nil))
      .update(:years => nil)
  end

  down do
  end

end
