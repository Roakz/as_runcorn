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

  RAPPropagateState = Struct.new(:record_model, :record_id, :applicable_rap_id, :completed)

  def propagate_raps!
    default_rap_id = RAP.get_default_id

    # Walk from the resource, breadth-first, all the way down the tree to its
    # representations.  Each branch we're exploring will have a currently active
    # RAP (starting with the default one).  When we reach a representation, if
    # the RAP we've calculated is different to what it has, the calculated RAP
    # becomes the new active one.

    queue = [RAPPropagateState.new(Resource, self.id, default_rap_id)]
    completed = []

    while !queue.empty?
      next_layer = []

      while !queue.empty?
        node = queue.shift

        applicable_rap_id = if node.record_model.ancestors.include?(RAPs)
                              # This node might have its own RAP.  If it does,
                              # we'll apply that to anything below this node in
                              # the tree.
                              if rap = RAP[:"#{node.record_model.table_name}_id" => node.record_id]
                                rap.id
                              else
                                # No new RAP found.  Keep the one we had.
                                node.applicable_rap_id
                              end
                            else
                              # No change because this node doesn't support RAPs being attached directly (i.e. it's a Resource)
                              node.applicable_rap_id
                            end

        if node.record_model == PhysicalRepresentation || node.record_model == DigitalRepresentation
          # Leaf nodes!  Sweet leaf nodes!
          completed << RAPPropagateState.new(node.record_model, node.record_id, applicable_rap_id, true)
        else
          if node.record_model == ArchivalObject
            # These can have representations attached to them.  Process those.
            [PhysicalRepresentation, DigitalRepresentation].each do |representation_model|
              representation_model.filter(:archival_object_id => node.record_id).select(:id).each do |representation|
                next_layer << RAPPropagateState.new(representation_model, representation[:id], applicable_rap_id)
              end
            end
          end

          # Search children
          if node.record_model == Resource
            ArchivalObject.filter(:parent_id => nil, :root_record_id => node.record_id).select(:id).each do |row|
              next_layer << RAPPropagateState.new(ArchivalObject, row[:id], applicable_rap_id)
            end
          else
            ArchivalObject.filter(:parent_id => node.record_id).select(:id).each do |row|
              next_layer << RAPPropagateState.new(ArchivalObject, row[:id], applicable_rap_id)
            end
          end
        end
      end

      queue = next_layer
    end

    # Finally, we can record any updated RAPs and mark them as applied
    DB.open do |db|
      completed.group_by(&:record_model).each do |representation_model, all_nodes|
        backlink_col = :"#{representation_model.table_name}_id"

        all_nodes.each_slice(500) do |sub_nodes|
          # Find the active RAPs for these records
          active_raps = {}

          db[:rap_applied]
            .filter(backlink_col => sub_nodes.map(&:record_id),
                    :is_active => 1)
            .select(backlink_col, :rap_id, :version)
            .each do |row|
            active_raps[row[backlink_col]] = row.to_h
          end

          # Some of these RAPs won't have changed.  Calculate which ones need updating.
          rows_to_insert = []
          sub_nodes.each do |node|
            if active_raps.include?(node.record_id)
              existing_rap = active_raps.fetch(node.record_id)
              if existing_rap[:rap_id] != node.applicable_rap_id
                # New RAP!
                rows_to_insert << {
                  backlink_col => node.record_id,
                  :rap_id => node.applicable_rap_id,
                  :version => existing_rap[:version] + 1,
                  :is_active => 1,
                }
              end
            else
              # No existing RAP.  Need a new row
              rows_to_insert << {
                backlink_col => node.record_id,
                :rap_id => node.applicable_rap_id,
                :version => 0,
                :is_active => 1,
              }
            end
          end

          # Any rows referencing our record are now inactive
          db[:rap_applied]
            .filter(backlink_col => rows_to_insert.map {|row| row.fetch(backlink_col)})
            .update(:is_active => 0)

          # And our new RAPs are ready to go
          db[:rap_applied].multi_insert(rows_to_insert)
        end
      end
    end
  end
end

