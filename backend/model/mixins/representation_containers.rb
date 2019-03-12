module RepresentationContainers

  def calculate_collections
    result = super

    resource_ids = []

    resource_ids +=  Resource
                      .join(:physical_representation, :physical_representation__resource_id => :resource__id)
                      .join(:sub_container, :sub_container__physical_representation_id => :physical_representation__id)
                      .join(:top_container_link_rlshp, :top_container_link_rlshp__sub_container_id => :sub_container__id)
                      .filter(:top_container_link_rlshp__top_container_id => id)
                      .select(:resource__id)
                      .distinct
                      .all.map{|row| row[:id]}

    resource_ids += Resource
                      .join(:archival_object, :archival_object__root_record_id => :resource__id)
                      .join(:physical_representation, :physical_representation__archival_object_id => :archival_object__id)
                      .join(:sub_container, :sub_container__physical_representation_id => :physical_representation__id)
                      .join(:top_container_link_rlshp, :top_container_link_rlshp__sub_container_id => :sub_container__id)
                      .filter(:top_container_link_rlshp__top_container_id => id)
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