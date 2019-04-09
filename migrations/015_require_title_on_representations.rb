require 'db/migrations/utils'

Sequel.migration do

  up do
    [:physical_representation, :digital_representation].each do |table|
      self[table].filter(:title => nil).update(:title => 'NO TITLE')
      alter_table(table) do
        set_column_not_null(:title)
      end
    end
  end

  down do
  end

end
