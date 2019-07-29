class Assessment
  include ExternalIDs
  include AssessmentFromConservationRequest

  define_relationship(:name => :assessment,
                      :json_property => 'records',
                      :contains_references_to_types => proc {[Accession, Resource, ArchivalObject, DigitalObject, PhysicalRepresentation]})


end
