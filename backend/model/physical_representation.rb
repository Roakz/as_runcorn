class PhysicalRepresentation < Sequel::Model(:physical_representation)
  include ASModel
  corresponds_to JSONModel(:physical_representation)

  include Deaccessions
  include Extents
  include ExternalIDs
  include Notes
  include Publishable

  define_relationship(:name => :representation_approved_by,
                      :json_property => 'approved_by',
                      :contains_references_to_types => proc {[AgentPerson]},
                      :is_array => false)

  set_model_scope :repository

  def self.ref_for(physical_representation_id)

    obj = PhysicalRepresentation[physical_representation_id]

    raise NotFoundException.new unless obj

    Representations.supported_models.each do |model|
      if obj[:"#{model.table_name}_id"]
        return model[obj[:"#{model.table_name}_id"]].uri
      end
    end

    raise NotFoundException.new
  end


  def self.sequel_to_jsonmodel(objs, opts = {})
    jsons = super

    objs.zip(jsons).each do |obj, json|
      json['existing_ref'] = obj.uri
    end

    jsons
  end

end
