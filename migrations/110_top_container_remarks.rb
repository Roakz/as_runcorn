require 'db/migrations/utils'

Sequel.migration do

  up do
    unless self[:top_container].columns.include?(:remarks)
      alter_table(:top_container) do
        add_column(:remarks, :text, :null => true)
      end
    end
  end
end
