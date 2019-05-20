class DigitalRepresentation < Sequel::Model(:digital_representation)
  include ASModel
  corresponds_to JSONModel(:digital_representation)

  include Deaccessions
  include ExternalIDs
  include Publishable

  include RepresentationControl

  define_relationship(:name => :representation_approved_by,
                      :json_property => 'approved_by',
                      :contains_references_to_types => proc {[AgentPerson]},
                      :is_array => false)

  define_relationship(:name => :representation_accession,
                      :json_property => 'related_accession',
                      :contains_references_to_types => proc {[Accession]},
                      :is_array => false)

  set_model_scope :repository


  def self.ref_for(digital_representation_id)

    obj = DigitalRepresentation[digital_representation_id]

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

    controlling_records_by_representation_id = self.build_controlling_record_map(objs)

    objs.zip(jsons).each do |obj, json|
      json['existing_ref'] = obj.uri
      json['display_string'] = build_display_string(json)

      controlling_record = controlling_records_by_representation_id.fetch(obj.id)
      json['responsible_agency'] = { 'ref' => controlling_record.responsible_agency }
      json['recent_responsible_agencies'] = controlling_record.recent_responsible_agencies
    end

    jsons
  end

  def self.build_display_string(json)
    json["title"] + '; ' + I18n.t("enumerations.runcorn_format.#{json["file_type"]}", default: json["file_type"])
  end

end
