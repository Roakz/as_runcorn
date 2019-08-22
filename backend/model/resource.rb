Resource.include(SeriesRepresentationCounts)
Resource.include(AllExistenceDates)
Resource.include(ReindexSeriesRepresentations)
Resource.include(RuncornDeaccession)
Resource.include(RAPs)
Resource.include(ControlGapsCalculator)

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

  def last_rap_applied_time
    result = DB.open do |db|
      [:physical_representation, :digital_representation].map {|representation_type|
        db[:archival_object]
          .join(representation_type, Sequel.qualify(representation_type, :archival_object_id) => Sequel.qualify(:archival_object, :id))
          .join(:rap_applied, Sequel.qualify(:rap_applied, :"#{representation_type}_id") => Sequel.qualify(representation_type, :id))
          .filter(Sequel.qualify(:archival_object, :root_record_id) => self.id)
          .max(:date_applied)
      }.compact.max
    end

    result || 0
  end

  def self.rap_reference(model, id)
    [model, id]
  end

  def self.rap_load_tree(db, resource_id)
    # Load the entire tree structure into memory.  This includes all
    # ArchivalObjects and their representations.
    record_parents = []

    # AOs
    db[:archival_object]
      .filter(:root_record_id => resource_id)
      .select(:id, :parent_id)
      .each do |row|
      if row[:parent_id]
        record_parents << [
          rap_reference(ArchivalObject, row[:id]),
          rap_reference(ArchivalObject, row[:parent_id]),
        ]
      else
        record_parents << [
          rap_reference(ArchivalObject, row[:id]),
          rap_reference(Resource, resource_id),
        ]
      end
    end

    # Representations...
    [PhysicalRepresentation, DigitalRepresentation].each do |representation_model|
      representation_table = representation_model.table_name

      db[representation_table]
        .join(:archival_object, Sequel.qualify(:archival_object, :id) => Sequel.qualify(representation_table, :archival_object_id))
        .filter(Sequel.qualify(:archival_object, :root_record_id) => resource_id)
        .select(Sequel.qualify(representation_table, :archival_object_id),
                Sequel.qualify(representation_table, :id))
        .each do |row|
        record_parents << [
          rap_reference(representation_model, row[:id]),
          rap_reference(ArchivalObject, row[:archival_object_id]),
        ]
      end
    end

    record_parents
  end

  def self.rap_load_connected_raps(db, resource_id)
    # Next we want to gather up all records in the tree with a RAP connected,
    # which might be Resource, ArchivalObject, PhysicalRepresentation or
    # DigitalRepresentation records.
    connected_raps = {}

    # Resource RAPs
    db[:rap].filter(:resource_id => resource_id).select(:resource_id, :id).each do |row|
      connected_raps[rap_reference(Resource, row[:resource_id])] = row[:id]
    end

    # AO RAPs
    db[:rap]
      .join(:archival_object, Sequel.qualify(:archival_object, :id) => Sequel.qualify(:rap, :archival_object_id))
      .filter(Sequel.qualify(:archival_object, :root_record_id) => resource_id)
      .select(Sequel.qualify(:rap, :id),
              Sequel.qualify(:rap, :archival_object_id))
      .each do |row|
      connected_raps[rap_reference(ArchivalObject, row[:archival_object_id])] = row[:id]
    end

    # PhysicalRepresentation RAPs
    db[:rap]
      .join(:physical_representation, Sequel.qualify(:physical_representation, :id) => Sequel.qualify(:rap, :physical_representation_id))
      .join(:archival_object, Sequel.qualify(:archival_object, :id) => Sequel.qualify(:physical_representation, :archival_object_id))
      .filter(Sequel.qualify(:archival_object, :root_record_id) => resource_id)
      .select(Sequel.qualify(:rap, :id),
              Sequel.qualify(:rap, :physical_representation_id))
      .each do |row|
      connected_raps[rap_reference(PhysicalRepresentation, row[:physical_representation_id])] = row[:id]
    end

    # DigitalRepresentation RAPs
    db[:rap]
      .join(:digital_representation, Sequel.qualify(:digital_representation, :id) => Sequel.qualify(:rap, :digital_representation_id))
      .join(:archival_object, Sequel.qualify(:archival_object, :id) => Sequel.qualify(:digital_representation, :archival_object_id))
      .filter(Sequel.qualify(:archival_object, :root_record_id) => resource_id)
      .select(Sequel.qualify(:rap, :id),
              Sequel.qualify(:rap, :digital_representation_id))
      .each do |row|
      connected_raps[rap_reference(DigitalRepresentation, row[:digital_representation_id])] = row[:id]
    end

    connected_raps
  end

  def self.drop_already_applied!(db, resource_id, new_raps)
    db[:rap_applied]
      .filter(Sequel.qualify(:rap_applied, :root_record_id) => resource_id)
      .filter(Sequel.~(Sequel.qualify(:rap_applied, :archival_object_id) => nil))
      .filter(Sequel.qualify(:rap_applied, :is_active) => 1)
      .select(Sequel.qualify(:rap_applied, :archival_object_id),
              Sequel.qualify(:rap_applied, :rap_id))
      .each do |row|
      if new_raps[rap_reference(ArchivalObject, row[:archival_object_id])] == row[:rap_id]
        # Already have this application.  No update needed.
        new_raps.delete(rap_reference(ArchivalObject, row[:archival_object_id]))
      end
    end

    db[:rap_applied]
      .filter(Sequel.~(Sequel.qualify(:rap_applied, :physical_representation_id) => nil))
      .filter(Sequel.qualify(:rap_applied, :root_record_id) => resource_id,
              Sequel.qualify(:rap_applied, :is_active) => 1)
      .select(Sequel.qualify(:rap_applied, :physical_representation_id),
              Sequel.qualify(:rap_applied, :rap_id))
      .each do |row|
      if new_raps[rap_reference(PhysicalRepresentation, row[:physical_representation_id])] == row[:rap_id]
        new_raps.delete(rap_reference(PhysicalRepresentation, row[:physical_representation_id]))
      end
    end

    db[:rap_applied]
      .filter(Sequel.~(Sequel.qualify(:rap_applied, :digital_representation_id) => nil))
      .filter(Sequel.qualify(:rap_applied, :root_record_id) => resource_id,
              Sequel.qualify(:rap_applied, :is_active) => 1)
      .select(Sequel.qualify(:rap_applied, :digital_representation_id),
              Sequel.qualify(:rap_applied, :rap_id))
      .each do |row|
      if new_raps[rap_reference(DigitalRepresentation, row[:digital_representation_id])] == row[:rap_id]
        new_raps.delete(rap_reference(DigitalRepresentation, row[:digital_representation_id]))
      end
    end

    new_raps
  end

  def self.rap_update_locks_and_mtimes(raps_applied)
    raps_applied.keys
      .group_by {|rap_reference| rap_reference[0]}
      .each do |model, references|
      model.update_mtime_for_ids(references.map {|reference| reference[1]})
    end

    # Find any AOs linked to any updated representations and bump those as well
    archival_object_ids = raps_applied.keys
                            .group_by {|rap_reference| rap_reference[0]}
                            .flat_map do |model, references|
      if model == ArchivalObject
        references.map {|reference| reference[1]}
      else
        # PhysicalRepresentation or DigitalRepresentation
        model
          .filter(:id => references.map {|reference| reference[1]})
          .select(:archival_object_id)
          .map {|row| row[:archival_object_id]}
          .uniq
      end
    end

    # Reindex their connected AOs too, and bump their lock versions to
    # ensure we get a new history entry.
    ArchivalObject.update_mtime_for_ids(archival_object_ids)
    ArchivalObject.filter(:id => archival_object_ids).update(:lock_version => Sequel.expr(1) + :lock_version)
  end

  def self.propagate_raps!(resource_id)
    default_rap_id = RAP.get_default_id
    start_time = Time.now

    DB.open do |db|
      record_parents = rap_load_tree(db, resource_id)
      connected_raps = rap_load_connected_raps(db, resource_id)

      # If the resource doesn't have a RAP, it takes the system default
      connected_raps[rap_reference(Resource, resource_id)] ||= default_rap_id

      Log.info("Resource: %d" % [resource_id])
      Log.info("Tree size: %d" % [record_parents.length])
      Log.info("Connected RAPs: %d" % [connected_raps.length])

      Log.info("Loaded tree structure and existing RAPs in %d ms" % [((Time.now.to_f - start_time.to_f) * 1000).to_i])

      record_raps_applied = {rap_reference(Resource, resource_id) => connected_raps[rap_reference(Resource, resource_id)]}
      start_time = Time.now
      processed = 0

      # Trivial case: records with a RAP attached have that RAP applied.
      record_parents.length.times do |idx|
        id, parent_id = record_parents.fetch(idx)

        if connected_raps[id]
          record_raps_applied[id] = connected_raps[id]

          processed += 1
          record_parents[idx] = nil
        end
      end

      # Everyone else needs a tree search
      while processed < record_parents.length
        old_processed = processed

        record_parents.length.times do |idx|
          id, parent_id = record_parents.fetch(idx)

          # We've already processed this entry
          next if id.nil?

          # If the parent has a RAP, apply it to the child
          if record_raps_applied[parent_id]
            record_raps_applied[id] = record_raps_applied[parent_id]

            processed += 1
            record_parents[idx] = nil
          end
        end

        raise "RAP deadlock detected after processing %d records" % [processed] if old_processed == processed
      end

      $stderr.puts("RAPs calculated in %d ms" % [((Time.now.to_f - start_time.to_f) * 1000).to_i])

      record_raps_applied.delete(rap_reference(Resource, resource_id))
      drop_already_applied!(db, resource_id, record_raps_applied)

      ## Apply any remaining changes

      # Any rows referencing our records are now inactive
      record_raps_applied.group_by {|record_reference, _|
        record_reference[0]
      }.each do |record_model, references_to_raps|
        backlink_col = :"#{record_model.table_name}_id"

        record_ids = references_to_raps.map {|record_reference, rap_id| record_reference[1]}        

        record_ids.slice(1000) do |id_subset|
          db[:rap_applied]
            .filter(backlink_col => id_subset)
            .update(:is_active => 0)
        end
      end


      # Insert our rows
      now = java.sql.Timestamp.new(java.util.Date.new.getTime)

      updated_count = 0

      # Dropping to JDBC here to keep memory usage under control while
      # inserting.  Sequel builds up SQL strings that end up being large when
      # there are millions of rows.
      db.transaction do |jdbc_conn|
        record_raps_applied.group_by {|record_reference, _|
          record_reference[0]
        }.each do |record_model, references_to_raps|
          backlink_col = "#{record_model.table_name}_id"

          ps = jdbc_conn.prepare_statement("insert into rap_applied (date_applied, rap_id, #{backlink_col}, is_active, root_record_id) values (?, ?, ?, ?, ?)")

          count = 0
          references_to_raps.each do |(record_model, record_id), rap_id|
            count += 1
            ps.setTimestamp(1, now)
            ps.setInt(2, rap_id)
            ps.setInt(3, record_id)
            ps.setInt(4, 1)
            ps.setInt(5, resource_id)

            ps.addBatch

            updated_count += 1

            if (count % 1000) == 0
              ps.executeBatch
            end
          end

          ps.executeBatch
        end
      end

      rap_update_locks_and_mtimes(record_raps_applied)

      updated_count
    end
  end


  # Returns a count of inserted rows.
  def propagate_raps!
    if RequestContext.active? && RequestContext.get(:deferred_rap_propagation_resource_ids)
      # Defer propagating.  Used for things like batch import.
      RequestContext.get(:deferred_rap_propagation_resource_ids) << self.id
    else
      # Propagate immediately
      self.class.propagate_raps!(self.id)
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

