Resource.include(SeriesRepresentationCounts)
Resource.include(AllExistenceDates)
Resource.include(ReindexSeriesRepresentations)
Resource.include(RuncornDeaccession)
Resource.include(RAPs)

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

          # Set applied_date on new rows
          now = Time.now
          rows_to_insert.each do |row|
            row[:date_applied] = now
          end

          # And our new RAPs are ready to go
          db[:rap_applied].multi_insert(rows_to_insert)
        end
      end
    end
  end

  def generate_rap_summary
    DB.open do |db|
      rap_id_to_summary = {}

      # grab the default rap
      db[:rap]
        .filter(:default_for_repo_id => RequestContext.get(:repo_id))
        .each do |row|
        rap_id_to_summary[row[:id]] = {
          "default_repo_rap" => true,
          "rap" => {
            "ref" => JSONModel(:rap).uri_for(row[:id], :repo_id => RequestContext.get(:repo_id)),
          },
          "attached_to" => {
            "ref" => JSONModel(:repository).uri_for(RequestContext.get(:repo_id)),
          },
          "digital_representation_count" => 0,
          "physical_representation_count" => 0,
        }
      end

      db[:resource]
        .join(:rap, Sequel.qualify(:rap, :resource_id) => Sequel.qualify(:resource, :id))
        .filter(Sequel.qualify(:resource, :id) => self.id)
        .select(Sequel.qualify(:rap, :id))
        .each do |row|
        rap_id_to_summary[row[:id]] = {
          "default_repo_rap" => false,
          "rap" => {
            "ref" => JSONModel(:rap).uri_for(row[:id], :repo_id => RequestContext.get(:repo_id)),
          },
          "attached_to" => {
            "ref" => self.uri,
          },
          "digital_representation_count" => 0,
          "physical_representation_count" => 0,
        }
      end

      db[:archival_object]
        .join(:rap, Sequel.qualify(:rap, :archival_object_id) => Sequel.qualify(:archival_object, :id))
        .filter(Sequel.qualify(:archival_object, :root_record_id) => self.id)
        .select(Sequel.qualify(:rap, :id),
                Sequel.qualify(:rap, :archival_object_id))
        .each do |row|
        rap_id_to_summary[row[:id]] = {
          "default_repo_rap" => false,
          "rap" => {
            "ref" => JSONModel(:rap).uri_for(row[:id], :repo_id => RequestContext.get(:repo_id)),
          },
          "attached_to" => {
            "ref" => JSONModel(:archival_object).uri_for(row[:archival_object_id], :repo_id => RequestContext.get(:repo_id)),
          },
          "digital_representation_count" => 0,
          "physical_representation_count" => 0,
        }
      end

      db[:digital_representation]
        .join(:rap, Sequel.qualify(:rap, :digital_representation_id) => Sequel.qualify(:digital_representation, :id))
        .join(:archival_object, Sequel.qualify(:archival_object, :id) => Sequel.qualify(:digital_representation, :archival_object_id))
        .filter(Sequel.qualify(:archival_object, :root_record_id) => self.id)
        .select(Sequel.qualify(:rap, :id),
                Sequel.qualify(:rap, :digital_representation_id))
        .each do |row|
        rap_id_to_summary[row[:id]] = {
          "default_repo_rap" => false,
          "rap" => {
            "ref" => JSONModel(:rap).uri_for(row[:id], :repo_id => RequestContext.get(:repo_id)),
          },
          "attached_to" => {
            "ref" => JSONModel(:digital_representation).uri_for(row[:digital_representation_id], :repo_id => RequestContext.get(:repo_id)),
          },
          "digital_representation_count" => 0,
          "physical_representation_count" => 0,
        }
      end

      db[:physical_representation]
        .join(:rap, Sequel.qualify(:rap, :physical_representation_id) => Sequel.qualify(:physical_representation, :id))
        .join(:archival_object, Sequel.qualify(:archival_object, :id) => Sequel.qualify(:physical_representation, :archival_object_id))
        .filter(Sequel.qualify(:archival_object, :root_record_id) => self.id)
        .select(Sequel.qualify(:rap, :id),
                Sequel.qualify(:rap, :physical_representation_id))
        .each do |row|
        rap_id_to_summary[row[:id]] = {
          "default_repo_rap" => false,
          "rap" => {
            "ref" => JSONModel(:rap).uri_for(row[:id], :repo_id => RequestContext.get(:repo_id)),
          },
          "attached_to" => {
            "ref" => JSONModel(:physical_representation).uri_for(row[:physical_representation_id], :repo_id => RequestContext.get(:repo_id)),
          },
          "digital_representation_count" => 0,
          "physical_representation_count" => 0,
        }
      end

      db[:rap_applied]
        .join(:digital_representation, Sequel.qualify(:digital_representation, :id) => Sequel.qualify(:rap_applied, :digital_representation_id))
        .join(:archival_object, Sequel.qualify(:archival_object, :id) => Sequel.qualify(:digital_representation, :archival_object_id))
        .filter(Sequel.qualify(:archival_object, :root_record_id) => self.id)
        .filter(:rap_id => rap_id_to_summary.keys)
        .filter(:is_active => 1)
        .filter(Sequel.~(:digital_representation_id => nil))
        .group_and_count(:rap_id)
        .each do |row|
        rap_id_to_summary.fetch(row[:rap_id])["digital_representation_count"] = row[:count]
      end

      db[:rap_applied]
        .join(:physical_representation, Sequel.qualify(:physical_representation, :id) => Sequel.qualify(:rap_applied, :physical_representation_id))
        .join(:archival_object, Sequel.qualify(:archival_object, :id) => Sequel.qualify(:physical_representation, :archival_object_id))
        .filter(Sequel.qualify(:archival_object, :root_record_id) => self.id)
        .filter(:rap_id => rap_id_to_summary.keys)
        .filter(:is_active => 1)
        .filter(Sequel.~(:physical_representation_id => nil))
        .group_and_count(:rap_id)
        .each do |row|
        rap_id_to_summary.fetch(row[:rap_id])["physical_representation_count"] = row[:count]
      end

      JSONModel(:rap_summary).from_hash({
        "raps" => rap_id_to_summary.values
      })
    end
  end
end

