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

  def self.sequel_to_jsonmodel(objs, opts = {})
    jsons = super

    # FUTURE NOTE: Public Access Requests and Exhibitions should be added to the
    # list of included context_uris once they're implemented.
    if rand < 0.01
      Log.warn("HEY: Currently this query only supports file issues because Public Access Requests and Exhibitions haven't been implemented yet.  Once they exist, find this message and await further instructions.")
    end

    frequency_of_use = Movement
                         .filter(:physical_representation_id => objs.map(&:id))
                         .filter(Sequel.|(
                                   Sequel.like(:context_uri, '/file_issues/%'))
                                )
                         .group_and_count(:physical_representation_id)
                         .map {|row| [row[:physical_representation_id], row[:count]]}
                         .to_h

    controlling_records_by_representation_id = self.build_controlling_record_map(objs)

    assessments_map = build_assessments_map(objs)

    controlling_records_qsa_id_map = build_controlling_records_qsa_id_map(controlling_records_by_representation_id)
    controlling_records_dates_map = build_controlling_records_dates_map(controlling_records_by_representation_id)

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
      json['responsible_agency'] = { 'ref' => controlling_record.responsible_agency }
      json['recent_responsible_agencies'] = controlling_record.recent_responsible_agencies

      json['deaccessioned'] = !json['deaccessions'].empty? || controlling_record.deaccessioned?

      json['frequency_of_use'] = frequency_of_use.fetch(obj.id, 0)

      json['assessments'] = assessments_map.fetch(obj.id, []).map{|uri| { 'ref' => uri }}
    end

    jsons
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

  def self.generate_treatments!(qsa_ids, assessment_id = nil)
    username = RequestContext.get(:current_username)
    user_agent_id = User[:username => username][:agent_record_id]

    now = Time.now

    treatment_row = {
      :physical_representation_id => 'SETME',
      :status => 'awaiting_treatment',
      :json_schema_version => 1,
      :lock_version => 0,
      :created_by => username,
      :last_modified_by => username,
      :create_time => now,
      :system_mtime => now,
      :user_mtime => now,
    }

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

      user_rlshp_row[:conservation_treatment_id] = treatment_id
      db[:conservation_treatment_user_rlshp].insert(user_rlshp_row)

      if assessment_id
        assessment_rlshp_row[:conservation_treatment_id] = treatment_id
        db[:conservation_treatment_assessment_rlshp].insert(assessment_rlshp_row)
      end
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

  private

  def self.build_assessments_map(objs)
    result = {}

    Assessment.find_relationship(:assessment)
      .find_by_participant_ids(self, objs.map(&:id))
      .each do |relationship|
        assessment_id = relationship[:assessment_id]
        result[relationship[:physical_representation_id]] ||= []
        result[relationship[:physical_representation_id]] << JSONModel(:assessment).uri_for(assessment_id, :repo_id => RequestContext.get(:repo_id))
    end

    result
  end

  def self.build_controlling_records_qsa_id_map(controlling_records_by_representation_id)
    qsa_ids_by_record_uri = {}

    ao_ids = controlling_records_by_representation_id.values.map(&:id)
    ArchivalObject
      .filter(:id => ao_ids)
      .select(:repo_id, :id, :qsa_id)
      .each do |row|
      record_uri = JSONModel(:archival_object).uri_for(row[:id], :repo_id => row[:repo_id])
      qsa_ids_by_record_uri[record_uri] = {
        :qsa_id => row[:qsa_id],
        :qsa_id_prefixed => QSAId.prefixed_id_for(ArchivalObject, row[:qsa_id]),
      }
    end

    resource_ids = controlling_records_by_representation_id.values.map(&:root_record_id)
    Resource
      .filter(:id => resource_ids)
      .select(:repo_id, :id, :qsa_id)
      .each do |row|
      record_uri = JSONModel(:resource).uri_for(row[:id], :repo_id => row[:repo_id])
      qsa_ids_by_record_uri[record_uri] = {
        :qsa_id => row[:qsa_id],
        :qsa_id_prefixed => QSAId.prefixed_id_for(Resource, row[:qsa_id]),
      }
    end

    qsa_ids_by_record_uri
  end

  def self.build_controlling_records_dates_map(controlling_records_by_representation_id)
    dates_by_record_id = {}

    ao_ids = controlling_records_by_representation_id.values.map(&:id)
    ASDate
      .filter(:archival_object_id => ao_ids)
      .select(:archival_object_id, :begin, :end)
      .each do |row|
      dates_by_record_id[row[:archival_object_id]] = {
        :begin => row[:begin],
        :end => row[:end],
      }
    end

    dates_by_record_id
  end
end
