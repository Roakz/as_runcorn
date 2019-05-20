require 'db/migrations/utils'

Sequel.migration do

  up do
    create_editable_enum('runcorn_charge_quantity_unit', ['order', 'record', 'page', 'qtr_hour'])

    create_table(:chargeable_item) do
      primary_key :id
      Integer :lock_version, :default => 0, :null => false

      TextField :description, :null => false
      Integer :price_cents, :null => false
      DynamicEnum :charge_quantity_unit_id, :null => false

      apply_mtime_columns
    end

    create_table(:chargeable_service) do
      primary_key :id
      Integer :lock_version, :default => 0, :null => false

      String :name, :null => false
      TextField :description, :null => false

      apply_mtime_columns
    end

    create_table(:chargeable_service_item_rlshp) do
      primary_key :id

      Integer :chargeable_item_id
      Integer :chargeable_service_id
      Integer :aspace_relationship_position

      apply_mtime_columns(false)
    end

    alter_table(:chargeable_service_item_rlshp) do
      add_foreign_key([:chargeable_item_id], :chargeable_item, :key => :id)
      add_foreign_key([:chargeable_service_id], :chargeable_service, :key => :id)
    end

    create_table(:service_quote) do
      primary_key :id
      Integer :lock_version, :default => 0, :null => false
      apply_mtime_columns
    end

    create_table(:service_quote_service_rlshp) do
      primary_key :id

      Integer :service_quote_id
      Integer :chargeable_service_id
      Integer :aspace_relationship_position

      apply_mtime_columns(false)
    end

    alter_table(:service_quote_service_rlshp) do
      add_foreign_key([:service_quote_id], :service_quote, :key => :id)
      add_foreign_key([:chargeable_service_id], :chargeable_service, :key => :id)
    end

    create_table(:service_quote_line) do
      primary_key :id
      Integer :lock_version, :default => 0, :null => false

      Integer :service_quote_id, :null => false
      Integer :quantity, :null => false

      TextField :description, :null => false
      Integer :charge_per_unit_cents, :null => false
      DynamicEnum :charge_quantity_unit_id, :null => false

      apply_mtime_columns
    end

    alter_table(:service_quote_line) do
      add_foreign_key([:service_quote_id], :service_quote, :key => :id)
    end

    create_table(:service_quote_line_item_rlshp) do
      primary_key :id

      Integer :service_quote_line_id
      Integer :chargeable_item_id
      Integer :aspace_relationship_position

      apply_mtime_columns(false)
    end

    alter_table(:service_quote_line_item_rlshp) do
      add_foreign_key([:service_quote_line_id], :service_quote_line, :key => :id)
      add_foreign_key([:chargeable_item_id], :chargeable_item, :key => :id)
    end

  end

  down do
  end

end
