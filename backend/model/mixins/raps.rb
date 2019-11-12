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
    RAPs.apply_raps(obj, json, :update)
    obj
  end

  module ClassMethods
    def create_from_json(json, extra_values = {})
      obj = super
      RAPs.apply_raps(obj, json, :create)
      obj
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


  def reset_publish_based_on_rap_applied!
    if AppConfig[:plugins].include?('qsa_migration_adapter')
      # Nothing to do if we're in migration land
      return
    end

    # If RAP propagation is deferred, we're in an import and don't want to
    # monkey with the publish flag anyway.
    return if RAP.deferred_propagations_active?

    self.refresh

    return if self.publish != 1 # do nothing if unpublished

    rap_data = RAPsApplied::RAPApplications.new([self])

    rap = rap_data.rap_json_for_rap_applied(self.id)

    return if rap.open_access_metadata

    rap_expiry = rap_data.rap_expiration_for_rap_applied(self.id)

    return if rap_expiry.fetch('expired')

    # Ok, the RAP implies that the record cannot be published
    self.publish = 0
    self.save
  end


  def self.apply_raps(obj, json, action)
    needs_rap_created = json.rap_attached && !json.rap_attached['uri']

    if needs_rap_created
      backlink = {:"#{obj.class.table_name}_id" => obj.id}

      rap = json['rap_attached']

      # null out backlink in anticipation of new RAP
      RAP.filter(backlink).update(RAPs.supported_models.map {|model| [:"#{model.table_name}_id", nil]}.to_h)

      RAP.create_from_json(JSONModel(:rap).from_hash(rap), backlink)
      obj.mark_as_system_modified
    end

    if needs_rap_created || action == :create
      if obj.is_a?(ArchivalObject)
        Resource[obj.root_record_id].propagate_raps!
      elsif obj.is_a?(Resource)
        obj.propagate_raps!
      else
        # Representations
        ao = ArchivalObject[obj.archival_object_id]
        Resource[ao.root_record_id].propagate_raps!(obj.archival_object_id)
      end
    end

    # publish check...
    obj.reset_publish_based_on_rap_applied!
  end

end
