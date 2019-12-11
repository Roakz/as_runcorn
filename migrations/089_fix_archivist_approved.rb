require 'db/migrations/utils'

Sequel.migration do

  up do
    [:resource, :archival_object, :physical_representation].each do |tbl|
      self[tbl].filter(:archivist_approved => nil).update(:archivist_approved => 0)

      alter_table(tbl) do
        set_column_not_null(:archivist_approved)
        set_column_default(:archivist_approved, 0)
      end
    end
  end

end
