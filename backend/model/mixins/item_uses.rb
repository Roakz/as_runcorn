module ItemUses

  def self.included(base)
    base.extend(ClassMethods)

    # FIXME: this check is best done at start up, but this method requires the incluse call to come after the method in the including class
    #        which is ugly and unfortunate. Is there a better way?
    # unless base.methods.include?(:to_item_uses)
    #   raise "Classes including the ItemUses mixin must implement #to_item_uses(json) => [JSONModel(:item_use)]. This one doesn't: #{base}"
    # end
  end


  def update_from_json(json, opts = {}, apply_nested_records = true)
    ItemUse.save_uses(self.class.to_item_uses(json))

    super
  end

  module ClassMethods
    def to_item_uses(json)
      raise "Classes including the ItemUses mixin must implement #to_item_uses(json) => [JSONModel(:item_use)]. This one doesn't: #{self.class}"
    end


    def create_from_json(json, opts = {})
      ItemUse.save_uses(self.to_item_uses(json))

      super
    end


    def sequel_to_jsonmodel(objs, opts = {})
      jsons = super

      objs.zip(jsons).each do |obj, json|
        # maybe give ref to list of item uses
      end

      jsons
    end
  end
end
