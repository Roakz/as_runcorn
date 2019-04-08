Resource.include(SeriesRepresentationCounts)
Resource.include(AllExistenceDates)

class Resource
  define_relationship(:name => :representation_approved_by,
                      :json_property => 'approved_by',
                      :contains_references_to_types => proc {[AgentPerson]},
                      :is_array => false)
end
