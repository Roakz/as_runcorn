class PhysicalRepresentation < Sequel::Model(:physical_representation)
  include ASModel
  corresponds_to JSONModel(:physical_representation)

  include Deaccessions
  include Extents
  include ExternalIDs
  include Publishable

  define_relationship(:name => :representation_approved_by,
                      :json_property => 'approved_by',
                      :contains_references_to_types => proc {[AgentPerson]},
                      :is_array => false)

  one_to_many :sub_container
  def_nested_record(:the_property => :containers,
                    :contains_records_of_type => :sub_container,
                    :corresponding_to_association => :sub_container)

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
      json['display_string'] = build_display_string(json)
    end

    jsons
  end

  def self.build_display_string(json)
    return json["title"] if json["title"]

    values = []
    values << json["description"]
    values << I18n.t("enumerations.runcorn_format.#{json["format"]}", default: json["format"])

    values.compact.join('; ')
  end

end
