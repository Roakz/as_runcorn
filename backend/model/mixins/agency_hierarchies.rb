# FIXME
require_relative '../../lib/dag'

module AgencyHierarchies

  CONTAINMENT_RELATIONSHIP = 'series_system_agent_agent_containment_relationship'

  def self.included(base)
    base.extend(ClassMethods)
  end

  def update_from_json(json, opts = {}, apply_nested_records = true)
    # If any containment relationships that were removed, we need to regenerate
    # the ancestor hierarchies starting with those records too.

    pre_update_linked_records = self.class.agency_ids_linked_via_containment([self.id])
    agency = super
    post_update_linked_records = self.class.agency_ids_linked_via_containment([self.id])

    self.class.regenerate_agency_hierarchies([self.id] + (pre_update_linked_records - post_update_linked_records))

    agency
  end

  def delete
    id = SecureRandom.hex

    DB.open do |db|
      linked_ids = self.class.agency_ids_linked_via_containment([self.id])
      linked_ids -= [self.id]

      graph_ids_to_regenerate = db[:agency_ancestor].filter(:agent_corporate_entity_id => self.id).select(:subgraph_id).distinct.map(:subgraph_id)
      db[:agency_ancestor].filter(:subgraph_id => graph_ids_to_regenerate).delete

      begin
        result = super
      ensure
        self.class.regenerate_agency_hierarchies(linked_ids)
      end

      result
    end
  end

  module ClassMethods

    def agency_ids_linked_via_containment(agency_ids)
      rlshp_defn = AgentCorporateEntity.find_relationship('series_system_agent_relationships')

      columns = rlshp_defn.reference_columns_for(AgentCorporateEntity)

      linked_ids = rlshp_defn
                     .find_by_participant_ids(AgentCorporateEntity, agency_ids)
                     .select {|relationship| (
                                relationship[:jsonmodel_type] == CONTAINMENT_RELATIONSHIP &&
                                relationship[:end_date].nil?
                              )}
                     .flat_map {|row| columns.map {|c| row[c]}}
                     .uniq

      linked_ids - agency_ids
    end

    def create_from_json(json, extra_values = {})
      agency = super
      regenerate_agency_hierarchies([agency.id])
      agency
    end

    def regenerate_agency_hierarchies(agency_ids)
      return if agency_ids.empty?

      graph_ids_to_regenerate = db[:agency_ancestor].filter(:agent_corporate_entity_id => agency_ids).select(:subgraph_id).distinct.map(:subgraph_id)
      db[:agency_ancestor].filter(:subgraph_id => graph_ids_to_regenerate).delete

      graph = DAG.new

      agency_ids.each do |id|
        graph.add_node(id)
      end

      processed_nodes = Set.new
      to_process = agency_ids.clone

      DB.open do |db|
        while !to_process.empty?
          new_nodes = []

          to_process.each do |id|
            processed_nodes << id
          end

          db[:series_system_rlshp]
            .join(:enumeration_value, Sequel.qualify(:series_system_rlshp, :relator_id) => Sequel.qualify(:enumeration_value, :id))
            .filter(:jsonmodel_type => CONTAINMENT_RELATIONSHIP)
            .filter(:end_date => nil)
            .filter(Sequel.|({:agent_corporate_entity_id_0 => to_process},
                             {:agent_corporate_entity_id_1 => to_process}))
            .select(Sequel.as(:agent_corporate_entity_id_0, :left),
                    Sequel.as(:agent_corporate_entity_id_1, :right),
                    Sequel.as(:relationship_target_id, :target),
                    Sequel.as(Sequel.qualify(:enumeration_value, :value), :relator))
            .each do |row|
            (parent_id, child_id) = if row[:relator] == 'is_contained_within'
                                      parent_id = row[:target]
                                      child_id = ([row[:left], row[:right]] - [parent_id]).first
                                      [parent_id, child_id]
                                    else
                                      child_id = row[:target]
                                      parent_id = ([row[:left], row[:right]] - [child_id]).first
                                      [parent_id, child_id]
                                    end

            graph.add_edge(parent: parent_id, child: child_id)
            new_nodes << parent_id unless processed_nodes.include?(parent_id)
            new_nodes << child_id unless processed_nodes.include?(child_id)
          end

          to_process = new_nodes
        end
      end

      graph.ancestors.each do |row|
        db[:agency_ancestor].insert(:ancestor_id => row.fetch(:ancestor),
                                    :agent_corporate_entity_id => row.fetch(:node),
                                    :subgraph_id => row.fetch(:subgraph_id))
      end
    end
  end
end
