class Assessment
  include ExternalIDs
  include AssessmentFromConservationRequest
  prepend AssessmentDisplayString

  define_relationship(:name => :assessment,
                      :json_property => 'records',
                      :contains_references_to_types => proc {[PhysicalRepresentation]})


  def check_if_assessed?(physical_representation_qsa_ids)
    assessment_representation_ids = related_records(:assessment).select{|record| record.is_a?(PhysicalRepresentation)}.map{|record| record[:qsa_id]}
    (physical_representation_qsa_ids - assessment_representation_ids).empty?
  end
end
