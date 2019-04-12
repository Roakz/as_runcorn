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

    def create_from_json(json, extra_values = {})
      agency = super
      self.class.regenerate_hierarchy_for_agencies
      agency
    end

    def regenerate_hierarchy_for_agencies
      DB.open do |db|
        ancestors = {}
        descendents = {}

        db[:agency_descendent].delete
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

          descendents.each do |_, path|
            if path.include?(parent_id)
              path << child_id
            end
          end 

          ancestors[child_id] ||= []
          ancestors[child_id] += ancestors.fetch(parent_id, []) + [parent_id]
          descendents[parent_id] ||= []
          descendents[parent_id] += descendents.fetch(child_id, []) + [child_id]
        end

        inserts = []
        descendents.map do |parent_id, descendent_ids|
          descendent_ids.each do |descendent_id|
            inserts << {
              :agent_corporate_entity_id => parent_id,
              :descendent_id => descendent_id,
            }
          end
        end

        db[:agency_descendent].multi_insert(inserts)

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