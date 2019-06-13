Resource.include(SeriesRepresentationCounts)
Resource.include(AllExistenceDates)
Resource.include(ReindexSeriesRepresentations)
Resource.include(RuncornDeaccession)

class Resource
  define_relationship(:name => :representation_approved_by,
                      :json_property => 'approved_by',
                      :contains_references_to_types => proc {[AgentPerson]},
                      :is_array => false)


  def self.sequel_to_jsonmodel(objs, opts = {})
    jsons = super

    jsons.each do |json|
      json['deaccessioned'] = !json['deaccessions'].empty?
    end

    jsons
  end

  def deaccessioned?
    !self.deaccession.empty?
  end

  def deaccession!
    self.children.each(&:deaccession!)
  end
end

