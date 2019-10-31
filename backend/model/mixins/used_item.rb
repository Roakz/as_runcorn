module UsedItem

  def self.included(base)
    base.extend(ClassMethods)
  end


  def item_was_used(use_identifier, opts)
    # ... thinks
  end


  module ClassMethods
    def sequel_to_jsonmodel(objs, opts = {})
      jsons = super

      objs.zip(jsons).each do |obj, json|
        # maybe give ref to list of uses
      end

      jsons
    end


    def handle_delete(ids_to_delete)
      ItemUse.filter(:physical_representation_id => ids_to_delete).each do |obj|
        obj.delete
      end

      super
    end
  end
end
