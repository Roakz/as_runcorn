require 'db/migrations/utils'

Sequel.migration do
  up do

    DESCRIPTION_CATEGORIES = {
      'Search fee' => 'Search',
      'Retrieval -- Standard' => 'Retrieval',
      'Delivery -- Standard (Tues & Thur) (no fee for delivery to QSA Reading Room)' => 'Delivery',
      'Additional fee for urgent orders (Urgent status is if required before next delivery day)' => 'Delivery',
      'Digital copy/scanning -- (1-20 pages; 300 ppi; up to A3 size; PDF)' => 'Scan',
      'Digital copy/scanning -- (21-50 pages; 300 ppi; up to A3 size; PDF)' => 'Scan',
      'Digital copy/scanning -- (51-100 pages; 300 ppi; up to A3 size; PDF)' => 'Scan',
      'Existing digitised record -- (number of pages not relevant, retrieval fee waived)' => 'Retrieval',
      'Additional fee for urgent scanning orders (Urgent status is if required before next delivery day)' => 'Scan',
    }

    self.transaction do
      enum_id = self[:enumeration][:name => 'runcorn_charge_category'][:id]
      enum_value_ids = self[:enumeration_value].filter(:enumeration_id => enum_id).map {|row|
        [row[:value], row[:id]]
      }.to_h


      DESCRIPTION_CATEGORIES.each do |description, category|
        self[:chargeable_item].filter(:description => description).update(:charge_category_id => enum_value_ids.fetch(category))
        self[:service_quote_line].filter(:description => description).update(:charge_category_id => enum_value_ids.fetch(category))
      end

      self[:chargeable_item].filter(:charge_category_id => nil).update(:charge_category_id => enum_value_ids.fetch('Other'))
      self[:service_quote_line].filter(:charge_category_id => nil).update(:charge_category_id => enum_value_ids.fetch('Other'))
    end

    alter_table(:chargeable_item) do
      set_column_not_null(:charge_category_id)
    end
  end
end
