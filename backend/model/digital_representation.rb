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

  include Transfers

  include Batchable

  include  SeriesRetentionStatus

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

    frequency_of_use = ItemUse.filter(:digital_representation_id => objs.map(&:id))
                              .group_and_count(:digital_representation_id)
                              .map {|row| [row[:digital_representation_id], row[:count]]}
                              .to_h

    controlling_records_by_representation_id = self.build_controlling_record_map(objs)

    controlling_records_qsa_id_map = build_controlling_records_qsa_id_map(controlling_records_by_representation_id)

    controlling_records_dates_map = build_controlling_records_dates_map(controlling_records_by_representation_id)

    deaccessioned_map = Deaccessioned.build_deaccessioned_map(controlling_records_by_representation_id.values.map(&:id))

    within_sets = {}
    MAPDB.open do |mapdb|
      mapdb[:file_issue_item]
        .join(:file_issue, Sequel.qualify(:file_issue, :id) => Sequel.qualify(:file_issue_item, :file_issue_id))
        .filter(:aspace_record_type => 'digital_representation')
        .filter(:aspace_record_id => objs.map(&:id))
        .select(Sequel.as(Sequel.qualify(:file_issue, :qsa_id), :file_issue_qsa_id),
                :file_issue_id,
                :aspace_record_id,
                :issue_type)
        .map do |row|
        within_sets[row[:aspace_record_id].to_i] ||= []
        within_sets[row[:aspace_record_id].to_i] << "%s%s%s" % [QSAId.prefix_for(FileIssue), row[:issue_type][0].upcase, row[:file_issue_qsa_id]]
      end
    end

    controlling_records_objs = controlling_records_by_representation_id.values.uniq
    responsible_agencies = ControlledRecord::ResponsibleAgencyCalculator.build_agency_control_map(controlling_records_objs)
    responsible_agencies = responsible_agencies.map {|obj, info| [obj.id, info]}.to_h
    recent_responsible_agencies = ControlledRecord::ResponsibleAgencyCalculator.build_recent_agency_control_map(controlling_records_objs)

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

      resource_uri = JSONModel(:resource).uri_for(controlling_record.root_record_id, :repo_id => controlling_record.repo_id)
      json['controlling_record_series'] = {
          'ref' => resource_uri,
          'qsa_id' => controlling_records_qsa_id_map.fetch(resource_uri).fetch(:qsa_id),
          'qsa_id_prefixed' => controlling_records_qsa_id_map.fetch(resource_uri).fetch(:qsa_id_prefixed),
      }

      new_agency_info = responsible_agencies.fetch(controlling_record.id)
      json['responsible_agency'] =  {
        'ref' => new_agency_info.agency_uri,
        'start_date' => new_agency_info.start_date,
        'inherited' => new_agency_info.inherited,
        'inherited_from' => new_agency_info.inherited_from,
        'overrides_series' => new_agency_info.overrides_series,
      }
      json['recent_responsible_agencies'] = recent_responsible_agencies.fetch([ArchivalObject, controlling_record.id])

      json['deaccessioned'] = !json['deaccessions'].empty? || deaccessioned_map.fetch(controlling_record.id)

      json['frequency_of_use'] = frequency_of_use.fetch(obj.id, 0)

      resource_uri = JSONModel(:resource).uri_for(controlling_record.root_record_id, :repo_id => controlling_record.repo_id)
      json['within'] = within_sets.fetch(obj.id, [])
      json['within'] << controlling_records_qsa_id_map.fetch(resource_uri).fetch(:qsa_id_prefixed)
      if obj.transfer_id
        json['within'] << QSAId.prefixed_id_for(Transfer, obj.transfer_id)
      end
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
