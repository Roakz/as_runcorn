require 'db/migrations/utils'

Sequel.migration do

  up do
    [
      :chargeable_service_item_rlshp,
      :representation_accession_rlshp,
      :representation_approved_by_rlshp,
      :representation_container_rlshp,
      :service_quote_line_item_rlshp,
      :service_quote_service_rlshp,
    ].each do |table|
      unless self[table].columns.include?(:suppressed)
        alter_table(table) do
          add_column(:suppressed, :integer,  :default => 0)
        end
      end
    end
  end

end
