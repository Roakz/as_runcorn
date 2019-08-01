module AssessmentFromConservationRequest

  def self.included(base)
    base.extend(ClassMethods)

    base.define_relationship(:name => :conservation_request_assessment,
                             :contains_references_to_types => proc {[ConservationRequest]},
                             :is_array => false)
  end

  module ClassMethods
    def create_from_json(json, opts = {})
      # If we're creating from a conservation request...
      if json['conservation_request_id']
        # Get refs for our linked records and load them all in
        conservation_request = ConservationRequest.get_or_die(json['conservation_request_id'])
        json['records'] = conservation_request.assigned_representation_refs.map {|uri|
          {'ref' => uri}
        }
      end

      obj = super

      if json['conservation_request_id']
        # Set the status of the conservation request
        conservation_request_json = ConservationRequest.to_jsonmodel(conservation_request)
        conservation_request_json.status = 'Assessment Created'
        conservation_request_json.assessment = {'ref' => obj.uri}
        conservation_request.update_from_json(conservation_request_json)
      end

      obj
    end

    def sequel_to_jsonmodel(objs, opts = {})
      # Don't return bajillions of records
      super(objs, opts.merge(:skip_relationships => [:assessment]))
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
