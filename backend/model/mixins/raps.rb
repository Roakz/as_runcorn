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
      # FIXME
      super
    end


    def sequel_to_jsonmodel(objs, opts = {})
      jsons = super

      backlink_col = :"#{table_name}_id"

      rap_jsons = {}
      raps = RAP.filter(backlink_col => objs.map(&:id)).all
      raps.zip(RAP.sequel_to_jsonmodel(raps)).each do |sequel_obj, json|
        rap_jsons[sequel_obj[backlink_col]] = json.to_hash
      end

      objs.zip(jsons).each do |obj, json|
        json['rap_attached'] = rap_jsons.fetch(obj.id, nil)
      end

      jsons
    end
  end


  def self.apply_raps(obj, json)
    return if json.rap_attached.nil?

    backlink = {:"#{obj.class.table_name}_id" => obj.id}

    rap = json['rap_attached']

    # null out backlink in anticipation of new RAP
    RAP.filter(backlink).update(RAPs.supported_models.map {|model| [:"#{model.table_name}_id", nil]}.to_h)

    RAP.create_from_json(JSONModel(:rap).from_hash(rap), backlink)
    obj.mark_as_system_modified

    if obj.is_a?(ArchivalObject)
      Resource[obj.root_record_id].propagate_raps!
    elsif obj.is_a?(Resource)
      obj.propagate_raps!
    else
      # Representations
      ao = ArchivalObject[obj.archival_object_id]
      Resource[ao.root_record_id].propagate_raps!
    end
  end

end
