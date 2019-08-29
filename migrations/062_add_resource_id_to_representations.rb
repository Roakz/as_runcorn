require 'db/migrations/utils'

Sequel.migration do

  up do
    alter_table(:physical_representation) do
      add_column :resource_id, Integer
      add_foreign_key([:resource_id], :resource, :key => :id)
    end
    alter_table(:digital_representation) do
      add_column :resource_id, Integer
      add_foreign_key([:resource_id], :resource, :key => :id)
    end

    self.transaction do
      self.run("update physical_representation set resource_id = (select root_record_id from archival_object where id = physical_representation.archival_object_id)")
      self.run("update digital_representation set resource_id = (select root_record_id from archival_object where id = digital_representation.archival_object_id)")
    end

    alter_table(:physical_representation) do
      set_column_not_null(:resource_id)
      add_index([:resource_id, :significance_id], :unique => false, :name => "physrep_significance_idx")
    end

    alter_table(:digital_representation) do
      set_column_not_null(:resource_id)
    end
  end

end
