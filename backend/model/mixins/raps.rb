module RAPs

  extend JSONModel

  def self.included(base)
    @supported_models ||= []
    @supported_models << base

    base.extend(ClassMethods)
  end

  def self.supported_models
    ASUtils.wrap(@supported_models)
  end

  def update_from_json(json, opts = {}, apply_nested_records = true)
    obj = super
    RAPs.apply_raps(obj, json)
    obj
  end

  module ClassMethods
    def create_from_json(json, extra_values = {})
      obj = super
      RAPs.apply_raps(obj, json)
      obj
    end

    def handle_delete(ids_to_delete)
      backlink_col = :"#{table_name}_id"

      # FIXME

      super
    end


    def sequel_to_jsonmodel(objs, opts = {})
      jsons = super

      # FIXME

      jsons
    end
  end


  def self.apply_raps(obj, json)
    # FIXME
  end

end