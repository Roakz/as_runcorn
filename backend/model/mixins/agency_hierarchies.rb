module AgencyHierarchies

  def self.included(base)
    base.extend(ClassMethods)
  end

  def update_from_json(json, opts = {}, apply_nested_records = true)
    agency = super
    self.class.regenerate_hierarchy_for_agencies
    agency
  end

  module ClassMethods

    def handle_delete(ids_to_delete)
      DB.open do |db|
        db[:agency_descendant].filter(:agent_corporate_entity_id => ids_to_delete).delete
        db[:agency_descendant].filter(:descendant_id => ids_to_delete).delete
        db[:agency_ancestor].filter(:agent_corporate_entity_id => ids_to_delete).delete
        db[:agency_ancestor].filter(:ancestor_id => ids_to_delete).delete
      end

      result = super

      regenerate_hierarchy_for_agencies

      result
    end

    def create_from_json(json, extra_values = {})
      agency = super
      self.regenerate_hierarchy_for_agencies
      agency
    end

    def regenerate_hierarchy_for_agencies
      DB.open do |db|
        ancestors = {}
        descendants = {}

        db[:agency_descendant].delete
        db[:agency_ancestor].delete

        db[:series_system_rlshp]
          .join(:enumeration_value, Sequel.qualify(:series_system_rlshp, :relator_id) => Sequel.qualify(:enumeration_value, :id))
          .filter(:jsonmodel_type => 'series_system_agent_agent_containment_relationship')
          .filter(:end_date => nil)
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

          ancestors.each do |_, path|
            if path.include?(child_id)
              path << parent_id
            end
          end

          descendants.each do |_, path|
            if path.include?(parent_id)
              path << child_id
            end
          end 

          ancestors[child_id] ||= []
          ancestors[child_id] += ancestors.fetch(parent_id, []) + [parent_id]
          descendants[parent_id] ||= []
          descendants[parent_id] += descendants.fetch(child_id, []) + [child_id]
        end

        inserts = []
        descendants.map do |parent_id, descendant_ids|
          descendant_ids.each do |descendant_id|
            inserts << {
              :agent_corporate_entity_id => parent_id,
              :descendant_id => descendant_id,
            }
          end
        end

        db[:agency_descendant].multi_insert(inserts)

        inserts = []
        ancestors.map do |child_id, ancestor_ids|
          ancestor_ids.each do |ancestor_id|
            inserts << {
              :agent_corporate_entity_id => child_id,
              :ancestor_id => ancestor_id,
            }
          end
        end
        db[:agency_ancestor].multi_insert(inserts)
      end
    end

  end
end
