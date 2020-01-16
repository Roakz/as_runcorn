ArchivalObject.include(Transfers)
ArchivalObject.include(Representations)
ArchivalObject.include(Deaccessions)
ArchivalObject.include(RuncornDeaccession)
ArchivalObject.include(RAPs)
ArchivalObject.include(RAPsApplied)
ArchivalObject.include(Significance)
ArchivalObject.include(Deaccessioned)
ArchivalObject.include(ArchivistApproval)

class ArchivalObject
  define_relationship(:name => :representation_approved_by,
                      :json_property => 'approved_by',
                      :contains_references_to_types => proc {[AgentPerson]},
                      :is_array => false)
end
