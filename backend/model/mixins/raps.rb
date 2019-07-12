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

    # Possibilities here:
    #
    #  We are creating a new AO/Representation with a new RAP (no existing_ref).  Create the RAP linked back to the AO/Representation and propagate.
    #
    #  We are updating an existing AO/Representation to include a new RAP (no existing_ref), and there wasn't one previously.  As above.
    #
    #  We are updating details of the RAP that is already attached to our AO/Representation.  existing_ref will match the backlink ID.  Do the update, no need to propagate.
    #
    #  We are updating an AO/Representation to include a new RAP (no existing_ref), but it replaces a RAP that was already there.  Apply the new RAP and propagate.
    #
    #  We are updating an AO/Representation to remove all RAPs.  Find nearest parent RAP and propagate it.
    #
    # Other cases to handle elsewhere:
    #
    #   Record re-ordering
    #
    #     - propagate whole tree
    #
    #   AO deleted with RAP attached -- find nearest parent RAP and propagate it
    #
    #   New representations added -- find nearest parent RAP and propagate it
    #
    #  Propagation: feasible just to do the whole tree?  Might be easier.

    backlink = {:"#{obj.class.table_name}_id" => obj.id}

    rap = json['rap_attached']

    if rap.fetch('existing_ref', nil)
      raise "FIXME: RAP update not yet implemented"
      # Maybe this is a new RAP?
    end

    RAP.create_from_json(JSONModel(:rap).from_hash(rap), backlink)
    obj.mark_as_system_modified

    Resource[obj.root_record_id].propagate_raps!
  end

end
