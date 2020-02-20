module Batchable

  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods
    def handle_delete(ids_to_delete)
      backlink_col = :"#{table_name}_id"

      DB.open do |db|
        db[:batch_objects].filter(backlink_col => ids_to_delete).delete
      end

      super
    end
  end
end