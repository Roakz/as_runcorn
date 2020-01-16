class DigitalRepresentation < Sequel::Model(:digital_representation)
  include ASModel
  corresponds_to JSONModel(:digital_representation)

  include Deaccessions
  include ExternalIDs
  include Publishable

  include RepresentationControl

  include RAPs
  include RAPsApplied

  include ArchivistApproval

  define_relationship(:name => :representation_approved_by,
                      :json_property => 'approved_by',
                      :contains_references_to_types => proc {[AgentPerson]},
                      :is_array => false)

  one_to_one :representation_file
  def_nested_record(:the_property => :representation_file,
                    :contains_records_of_type => :representation_file,
                    :corresponding_to_association  => :representation_file,
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

    controlling_records_qsa_id_map = build_controlling_records_qsa_id_map(controlling_records_by_representation_id)

    controlling_records_dates_map = build_controlling_records_dates_map(controlling_records_by_representation_id)

    deaccessioned_map = Deaccessioned.build_deaccessioned_map(controlling_records_by_representation_id.values.map(&:id))

    objs.zip(jsons).each do |obj, json|
      json['existing_ref'] = obj.uri
      json['display_string'] = build_display_string(json)

      controlling_record = controlling_records_by_representation_id.fetch(obj.id)
      json['controlling_record'] = {
        'ref' => controlling_record.uri,
        'qsa_id' => controlling_records_qsa_id_map.fetch(controlling_record.uri).fetch(:qsa_id),
        'qsa_id_prefixed' => controlling_records_qsa_id_map.fetch(controlling_record.uri).fetch(:qsa_id_prefixed),
        'begin_date' => controlling_records_dates_map.fetch(controlling_record.id, {}).fetch(:begin, nil),
        'end_date' => controlling_records_dates_map.fetch(controlling_record.id, {}).fetch(:end, nil),
      }
      json['responsible_agency'] = { 'ref' => controlling_record.responsible_agency.fetch(:uri),
                                     'start_date' => controlling_record.responsible_agency.fetch(:start_date)}
      json['recent_responsible_agencies'] = controlling_record.recent_responsible_agencies

      json['deaccessioned'] = !json['deaccessions'].empty? || deaccessioned_map.fetch(controlling_record.id)
    end

    jsons
  end

  def self.build_display_string(json)
    if json['file_type']
      json["title"] + '; ' + I18n.t("enumerations.runcorn_format.#{json["file_type"]}", default: json["file_type"])
    else
      json["title"]
    end
  end

end
