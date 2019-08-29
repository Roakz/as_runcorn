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
      #update physical_representation set mark_testing = (select root_record_id from archival_object where id = physical_representation.archival_object_id);
      self[:physical_representation].select(:id).all.each_slice(1000).each do |ids|
        self[:physical_representation]
          .join(:archival_object, Sequel.qualify(:archival_object, :id) => Sequel.qualify(:physical_representation, :archival_object_id))
          .select(Sequel.qualify(:physical_representation, :id),
                  Sequel.qualify(:archival_object, :root_record_id))
          .map do |row|
          [row[:id], row[:root_record_id]]
        end.each do |id, resource_id|
          self[:physical_representation]
            .filter(:id => id)
            .update(:resource_id => resource_id)
        end
      end

      self[:digital_representation].select(:id).all.each_slice(1000).each do |ids|
        self[:digital_representation]
          .join(:archival_object, Sequel.qualify(:archival_object, :id) => Sequel.qualify(:digital_representation, :archival_object_id))
          .select(Sequel.qualify(:digital_representation, :id),
                  Sequel.qualify(:archival_object, :root_record_id))
          .map do |row|
          [row[:id], row[:root_record_id]]
        end.each do |id, resource_id|
          self[:digital_representation]
            .filter(:id => id)
            .update(:resource_id => resource_id)
        end
      end
    end

    alter_table(:physical_representation) do
      set_column_not_null(:resource_id)
    end

    alter_table(:digital_representation) do
      set_column_not_null(:resource_id)
    end

  end

  down do
  end

end
