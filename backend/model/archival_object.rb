ArchivalObject.include(Transfers)
ArchivalObject.include(Representations)
ArchivalObject.include(Deaccessions)
ArchivalObject.include(RuncornDeaccession)
ArchivalObject.include(RAPs)

class ArchivalObject
  define_relationship(:name => :representation_approved_by,
                      :json_property => 'approved_by',
                      :contains_references_to_types => proc {[AgentPerson]},
                      :is_array => false)

  def self.sequel_to_jsonmodel(objs, opts = {})
    jsons = super

    objs.zip(jsons).each do |obj, json|
      json['deaccessioned'] = obj.deaccessioned?
    end

    jsons
  end

  def deaccessioned?
    return true if !self.deaccession.empty?

    if self.parent_id
      ArchivalObject[self.parent_id].deaccessioned?
    else
      Resource[self.root_record_id].deaccessioned?
    end
  end

  def deaccession!
    PhysicalRepresentation
      .filter(:archival_object_id => self.id)
      .each do |rep|
      rep.deaccession!
    end

    self.children.each(&:deaccession!)
  end
end
