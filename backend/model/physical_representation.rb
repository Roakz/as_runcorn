class PhysicalRepresentation < Sequel::Model(:physical_representation)
  include ASModel
  corresponds_to JSONModel(:physical_representation)

  include Deaccessions
  include Extents
  include ExternalIDs
  include Publishable

  include Movements

  include RepresentationControl
  include RuncornDeaccession

  include RAPs
  include RAPsApplied

  include ConservationRequests
  include ConservationTreatments

  include UsedItem

  include ArchivistApproval

  include ItemUses

  include Transfers

  include Batchable

  include SeriesRetentionStatus

  define_relationship(:name => :representation_approved_by,
                      :json_property => 'approved_by',
                      :contains_references_to_types => proc {[AgentPerson]},
                      :is_array => false)

  define_relationship(:name => :representation_container,
                      :json_property => 'container',
                      :contains_references_to_types => proc {[TopContainer]},
                      :is_array => false)

  # Apply reverse relationship so we don't mess with delete.
  TopContainer.define_relationship(:name => :representation_container,
                                   :contains_references_to_types => proc {[PhysicalRepresentation]})

  # Apply reverse relationship to assessments
  define_relationship(:name => :assessment,
                      :contains_references_to_types => proc{[Assessment]})


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


  def update_from_json(json, opts = {}, apply_nested_records = true)
    # If we're linked to a top container, reindex it to make sure its series
    # info is up-to-date.
    if json.container
      TopContainer.update_mtime_for_ids([JSONModel.parse_reference(json.container['ref']).fetch(:id)])
    end

    super
  end

  def self.handle_delete(ids_to_delete)
    ConservationRequest.clear_physical_representations(ids_to_delete)

    super
  end


  def self.sequel_to_jsonmodel(objs, opts = {})
    jsons = super

    frequency_of_use = ItemUse.filter(:physical_representation_id => objs.map(&:id))
                              .group_and_count(:physical_representation_id)
                              .map {|row| [row[:physical_representation_id], row[:count]]}
                              .to_h

    controlling_records_by_representation_id = self.build_controlling_record_map(objs)

    assessments_map = build_assessments_map(objs)

    controlling_records_qsa_id_map = build_controlling_records_qsa_id_map(controlling_records_by_representation_id)

    controlling_records_dates_map = build_controlling_records_dates_map(controlling_records_by_representation_id)

    availability_options = get_sorted_availability_options

    deaccessioned_map = Deaccessioned.build_deaccessioned_map(controlling_records_by_representation_id.values.map(&:id))

    within_sets = {}
    MAPDB.open do |mapdb|
      mapdb[:file_issue_item]
        .join(:file_issue, Sequel.qualify(:file_issue, :id) => Sequel.qualify(:file_issue_item, :file_issue_id))
        .filter(:aspace_record_type => 'physical_representation')
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

      json['assessments'] = assessments_map.fetch(obj.id, []).map{|assessment_blob| { 'ref' => assessment_blob.fetch(:uri) }}

      set_calculated_availability!(json, assessments_map.fetch(obj.id, []), controlling_records_dates_map.fetch(controlling_record.id, {}).fetch(:end, nil), availability_options)

      json['within'] = within_sets.fetch(obj.id, [])
      json['within'] << controlling_records_qsa_id_map.fetch(resource_uri).fetch(:qsa_id_prefixed)
      if obj.transfer_id
        json['within'] << QSAId.prefixed_id_for(Transfer, obj.transfer_id)
      end
    end

    jsons
  end

  def self.get_sorted_availability_options
    result = []

    DB.open do |db|
      availability_enum_id = db[:enumeration].filter(:name => 'runcorn_physical_representation_availability').select(:id)
      db[:enumeration_value]
        .filter(:enumeration_id => availability_enum_id)
        .order(Sequel.asc(:position))
        .select(:value)
        .each do |row|
        result << row[:value]
      end
    end

    result
  end

  AVAILABILITIES = {
    'available' => 0,                         # 1
    'unavailable_temporarily' => 400,         # 2
    'unavailable_due_to_conservation' => 500, # 3 requestable!
    'unavailable_due_to_condition' => 600,    # 4
    'unavailable_due_to_format' => 600,       # 5
    'unavailable_due_to_deaccession' => 999,  # 6 overrides all
    'unavailable_due_to_date_range' => 200,   # 7 requestable!
    'unavailable_contact_qsa' => 300,         # 8 requestable!
  }

  def self.set_calculated_availability!(json, assessments_for_representation, controlling_record_end_date, availability_options)
    candidate_availabilies = ['available', json['availability']].uniq.compact

    if json['deaccessioned']
      candidate_availabilies << 'unavailable_due_to_deaccession'
    end

    if controlling_record_end_date.nil?
      candidate_availabilies << 'unavailable_due_to_date_range'
    end

    # check conservation requests to determine if unavailable_due_to_conservation
    #  - conservation_request.status == 'Ready For Review'
    if ASUtils.wrap(json['conservation_requests']).any?{|cr| cr['status'] == 'Ready For Review'}
      candidate_availabilies << 'unavailable_due_to_conservation'
    end

    # check assessments to determine if unavailable_due_to_conservation
    #  - assessment.survey_begin == not null (active)
    if assessments_for_representation.any?{|assessment_blob| assessment_blob.fetch(:active)}
      candidate_availabilies << 'unavailable_due_to_conservation'
    end

    # check conservation treatments to determine if unavailable_due_to_conservation
    if json['conservation_treatments'].any?{|treatment| treatment['status'] != ConservationTreatment::STATUS_COMPLETED}
      candidate_availabilies << 'unavailable_due_to_conservation'
    end

    # check location!
    if ['CONS', 'SEE CON'].include?(json['current_location'])
      candidate_availabilies << 'unavailable_due_to_conservation'
    elsif json['current_location'] != 'HOME'
      candidate_availabilies << 'unavailable_temporarily'
    end

    json['calculated_availability'] = candidate_availabilies.max_by{|candidate| AVAILABILITIES.fetch(candidate)}
    json['calculated_availability_overrides_availability'] = json['availability'] != json['calculated_availability']
  end

  def self.build_display_string(json)
    json["title"] + '; ' + I18n.t("enumerations.runcorn_format.#{json["format"]}", default: json["format"])
  end

  def deaccession!
    self.my_relationships(:representation_container).each(&:delete)
  end

  def deaccessioned?
    return true if !self.deaccession.empty?

    ArchivalObject[self.archival_object_id].deaccessioned?
  end

  def self.generate_treatments!(qsa_ids, assessment_id, treatment_template)
    username = RequestContext.get(:current_username)
    user_agent_id = User[:username => username][:agent_record_id]
    treatment_template = treatment_template.select{|k,v| v && !v.empty?}
    status = ConservationTreatment.calculate_status(treatment_template)

    # All subrecords in this set will store the treatment batch id.  We'll use
    # this to link together instances of the same treatment.
    treatment_batch_id = Sequence.get("QSA_ASSESSMENT_TREATMENT_BATCH_ID").to_s

    now = Time.now

    applied_treatments = treatment_template.fetch('treatments', [])
    treatment_template.delete('treatments')

    treatment_row = {
      :treatment_batch_id => treatment_batch_id,
      :physical_representation_id => 'SETME',
      :status => status,
      :json_schema_version => 1,
      :lock_version => 0,
      :created_by => username,
      :last_modified_by => username,
      :create_time => now,
      :system_mtime => now,
      :user_mtime => now,
      :persistent_create_time => now,
    }.merge(treatment_template)

    applied_treatment_rows = applied_treatments.map do |attribute|
      {
        :conservation_treatment_id => 'SETME',
        :assessment_attribute_definition_id => attribute.fetch('definition_id'),
        :created_by => username,
        :last_modified_by => username,
        :system_mtime => now,
        :user_mtime => now,
      }
    end

    user_rlshp_row = {
      :conservation_treatment_id => 'SETME',
      :agent_person_id => user_agent_id,
      :aspace_relationship_position => 0,
      :created_by => username,
      :last_modified_by => username,
      :system_mtime => now,
      :user_mtime => now,
    }

    assessment_rlshp_row = {
      :conservation_treatment_id => 'SETME',
      :assessment_id => assessment_id,
      :aspace_relationship_position => 0,
      :created_by => username,
      :last_modified_by => username,
      :system_mtime => now,
      :user_mtime => now,
    }

    self
      .filter(:qsa_id => qsa_ids)
      .select(:id)
      .each do |row|
      representation_id = row[:id]

      treatment_row[:physical_representation_id] = representation_id
      treatment_id = db[:conservation_treatment].insert(treatment_row)

      applied_treatment_rows.each do |applied_treatment_row|
        applied_treatment_row[:conservation_treatment_id] = treatment_id
        db[:conservation_treatment_applied_treatment].insert(applied_treatment_row)
      end

      user_rlshp_row[:conservation_treatment_id] = treatment_id
      db[:conservation_treatment_user_rlshp].insert(user_rlshp_row)

      assessment_rlshp_row[:conservation_treatment_id] = treatment_id
      db[:conservation_treatment_assessment_rlshp].insert(assessment_rlshp_row)
    end

    # trigger a reindex of all representations
    self
      .filter(:qsa_id => qsa_ids)
      .update(:system_mtime => now)

    # update the AO lock version so we trigger an audit history record for
    # this action
    linked_ao_ids = self.filter(:qsa_id => qsa_ids).select(:archival_object_id)
    ArchivalObject.filter(:id => linked_ao_ids).update(:lock_version => Sequel.expr(1) + :lock_version, :system_mtime => now)
  end


  def self.to_item_uses(json)
    return [] unless json['existing_ref']
    exhibitions = []
    on_exhibition = false

    json['movements'].select{|m| m.has_key?('functional_location')}.sort{|a,b| a['move_date'] <=> b['move_date']}.each do |move|
      if move['functional_location'] == 'EXH'
        exhibitions.push({:start_date => move['move_date']})
        on_exhibition = true
      elsif on_exhibition
        exhibitions.last[:end_date] = move['move_date']
        on_exhibition = false
      end
    end

    exhibitions.map do |exh|
      JSONModel(:item_use).from_hash({
                                       'representation' => {'ref' => json['existing_ref']},
                                       'item_use_type' => 'exhibition',
                                       'use_identifier' => "EXHIBITION #{exh[:start_date]}",
                                       'status' => exh[:end_date] ? 'RETURNED' : 'EXHIBITION',
                                       'used_by' => RequestContext.get(:current_username),
                                       'start_date' => exh[:start_date],
                                       'end_date' => exh[:end_date],
                                     })
    end
  end


  private

  def self.build_assessments_map(objs)
    result = {}
    blob_by_id = {}

    Assessment.find_relationship(:assessment)
      .find_by_participant_ids(self, objs.map(&:id))
      .each do |relationship|
        assessment_id = relationship[:assessment_id]
        result[relationship[:physical_representation_id]] ||= []

        blob_by_id[assessment_id] ||=
          {
            uri: JSONModel(:assessment).uri_for(assessment_id, :repo_id => RequestContext.get(:repo_id)),
            id: assessment_id,
            active: false,
          }
        result[relationship[:physical_representation_id]] << blob_by_id[assessment_id]
    end

    Assessment
      .filter(:id => blob_by_id.keys)
      .select(:id, :survey_end)
      .map do |row|
      blob_by_id[row[:id]][:active] = row[:survey_end].nil?
    end

    result
  end
end
