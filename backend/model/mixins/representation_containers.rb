module RepresentationContainers

  def calculate_collections
    result = super

    resource_ids = []

    resource_ids += Resource
                      .join(:archival_object, :archival_object__root_record_id => :resource__id)
                      .join(:physical_representation, :physical_representation__archival_object_id => :archival_object__id)
                      .join(:representation_container_rlshp, :physical_representation__id => :representation_container_rlshp__top_container_id)
                      .filter(:representation_container_rlshp__top_container_id => id)
                      .select(:resource__id)
                      .distinct
                      .all.map{|row| row[:id]}

    result += Resource
                .filter(:id => resource_ids.uniq)
                .select_all(:resource)
                .all

    result.uniq {|obj| [obj.class, obj.id]}
  end

end
