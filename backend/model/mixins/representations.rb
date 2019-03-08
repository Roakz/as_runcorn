module Representations

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
    Representations.apply_representations(obj, json)
    obj
  end

  module ClassMethods
    def create_from_json(json, extra_values = {})
      obj = super
      Representations.apply_representations(obj, json)
      obj
    end

    def sequel_to_jsonmodel(objs, opts = {})
      jsons = super

      # Grab all referenced representations and slot them in
      backlink_col = :"#{self.table_name}_id"

      physical_representation_jsons = {}
      digital_representation_jsons = {}

      representations = PhysicalRepresentation.filter(backlink_col => objs.map(&:id)).all
      representations.zip(PhysicalRepresentation.sequel_to_jsonmodel(representations)).each do |sequel_obj, json|
        physical_representation_jsons[sequel_obj[backlink_col]] ||= []
        physical_representation_jsons[sequel_obj[backlink_col]] << json
      end

      representations = DigitalRepresentation.filter(backlink_col => objs.map(&:id)).all
      representations.zip(DigitalRepresentation.sequel_to_jsonmodel(representations)).each do |sequel_obj, json|
        digital_representation_jsons[sequel_obj[backlink_col]] ||= []
        digital_representation_jsons[sequel_obj[backlink_col]] << json
      end

      objs.zip(jsons).each do |obj, json|
        json['physical_representations'] = physical_representation_jsons.fetch(obj.id, [])
        json['digital_representations'] = digital_representation_jsons.fetch(obj.id, [])
      end

      jsons
    end
  end


  def self.apply_representations(obj, json)
    # Representations with refs get updated.  Otherwise, create new records.

    backlink = {:"#{obj.class.table_name}_id" => obj.id}

    [
      [PhysicalRepresentation, 'physical_representations', :physical_representation],
      [DigitalRepresentation, 'digital_representations', :digital_representation]
    ].each do |representation_class, representation_property, representation_jsonmodel|
      grouped = json[representation_property].group_by {|rep| rep['existing_ref']}

      ids_to_keep = grouped.keys.compact.map {|ref| JSONModel.parse_reference(ref)[:id]}

      representation_class
        .filter(backlink)
        .filter(Sequel.~(:id => ids_to_keep))
        .each(&:delete)

      # Create the ones that don't exist yet (no ref)
      ASUtils.wrap(grouped.delete(nil)).each do |to_create|
        representation_class.create_from_json(JSONModel(representation_jsonmodel).from_hash(to_create), backlink)
        obj.mark_as_system_modified
      end

      # Update the others
      grouped.each do |ref, to_update|
        # to_update is always a single element array since the ref ensures uniqueness within the set...
        id = JSONModel.parse_reference(ref)[:id]

        representation_class[id].update_from_json(JSONModel(representation_jsonmodel).from_hash(to_update[0]), backlink)
      end
    end
  end

end
