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
    Log.warn("HEY: Currently this query only supports file issues because Public Access Requests and Exhibitions haven't been implemented yet.  Once they exist, find this message and await further instructions.")

    frequency_of_use = Movement
                         .filter(:physical_representation_id => objs.map(&:id))
                         .filter(Sequel.|(
                                   Sequel.like(:context_uri, '/file_issues/%'))
                                )
                         .group_and_count(:physical_representation_id)
                         .map {|row| [row[:physical_representation_id], row[:count]]}
                         .to_h

    controlling_records_by_representation_id = self.build_controlling_record_map(objs)

    objs.zip(jsons).each do |obj, json|
      json['existing_ref'] = obj.uri
      json['display_string'] = build_display_string(json)

      controlling_record = controlling_records_by_representation_id.fetch(obj.id)
      json['controlling_record'] = { 'ref' => controlling_record.uri }
      json['controlling_record_series'] = { 'ref' => JSONModel(:resource).uri_for(controlling_record.root_record_id, :repo_id => controlling_record.repo_id) }
      json['responsible_agency'] = { 'ref' => controlling_record.responsible_agency }
      json['recent_responsible_agencies'] = controlling_record.recent_responsible_agencies

      json['deaccessioned'] = !json['deaccessions'].empty? || controlling_record.deaccessioned?

      json['frequency_of_use'] = frequency_of_use.fetch(obj.id, 0)
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

  def self.generate_treatments!(qsa_ids)
    user = User[:username => RequestContext.get(:current_username)]
    agent_uri = JSONModel(:agent_person).uri_for(user[:agent_record_id])

    self
      .filter(:qsa_id => qsa_ids)
      .select(:id)
      .each do |row|
      obj = PhysicalRepresentation[row[:id]]
      json = PhysicalRepresentation.to_jsonmodel(obj)
      json['conservation_treatments'] << {
        'user' => {
          'ref' => agent_uri
        }
      }
      obj.update_from_json(json)
    end
  end

end
