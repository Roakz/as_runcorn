module AssessmentFromConservationRequest

  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods
    def create_from_json(json, opts = {})
      # Get refs for our linked records and load them all in
      conservation_request = ConservationRequest.get_or_die(json['conservation_request_id'])
      json['records'] = conservation_request.assigned_representation_refs.map {|uri|
        {'ref' => uri}
      }

      obj = super
    end
  end


  def connected_record_refs
    Assessment.find_relationship(:assessment)
      .find_by_participant(self)
      .map {|relationship| relationship[:physical_representation_id]}
      .compact
      .map do |physical_representation_id|
      JSONModel(:physical_representation).uri_for(physical_representation_id, :repo_id => RequestContext.get(:repo_id))
    end
  end

  def update_from_json(json, opts = {}, apply_nested_records = true)
    # We need to make sure our set of records isn't cleared on update.  The
    # frontend won't pass the set through, but that doesn't mean we don't want
    # then
    json['records'] = connected_record_refs.map {|uri|
      {'ref' => uri}
    }

      super
  end


end
