Resource.include(SeriesRepresentationMetadata)
Resource.include(AllExistenceDates)
Resource.include(ReindexSeriesRepresentations)
Resource.include(RuncornDeaccession)
Resource.include(RAPs)
Resource.include(ControlGapsCalculator)
Resource.include(Deaccessioned)
Resource.include(ArchivistApproval)

class Resource
  define_relationship(:name => :representation_approved_by,
                      :json_property => 'approved_by',
                      :contains_references_to_types => proc {[AgentPerson]},
                      :is_array => false)

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

  class RapMapping
    def initialize(size_estimate)
      @size_estimate = size_estimate
      @store = {}
      @pending_deletes = Set.new
      @iterating = false
    end

    def add(record_model, record_id, rap_id)
      mapping = (@store[record_model] ||= java.util.HashMap.new(@size_estimate))
      mapping.put(record_id, rap_id)
    end

    def rap_for(record_model, record_id)
      @store.fetch(record_model, {})[record_id]
    end

    def delete(record_model, record_id)
      if @iterating
        # Can't delete from our map while we're iterating over it, so handle these specially.
        @pending_deletes << record_id
      else
        if @store.fetch(record_model, nil)
          @store[record_model].remove(record_id)
        end
      end
    end

    def each_chunk(chunk_size, &block)
      @iterating = true

      @store.keys.each do |record_model|
        entries = @store[record_model].entry_set

        entries.each_slice(chunk_size) do |chunk|
          block.call(record_model, chunk.map(&:key), chunk.map(&:value))

          # Apply deletes while at this safepoint
          chunk.each do |entry|
            if @pending_deletes.include?(entry.key)
              # Mark entry for delete.  We'll sweep at the end.
              entry.set_value(nil)
            end
          end

          @pending_deletes.clear
        end

        # Clear marked deletes
        it = entries.iterator
        while it.hasNext
          entry = it.next
          it.remove if entry.value.nil?
        end
      end
    ensure

      @iterating = false
    end

    def length
      @store.reduce(0) {|total, (_, map)| total + map.size}
    end
  end

  class RecordParents
    # Store child_id -> parent_id associations where parent & child might be of
    # different record types.
    #
    # This would most simply be stored as:
    #
    #   map[[child_model, child_id]] = [parent_model, parent_id]
    #
    # but that's a lot of memory when there are millions of records.  Instead,
    # we store an array of IDs (a "mapping") for each combination of child model
    # and parent model we care about.
    #
    # Within the mapping, the child's ID is stored at position i and its parent
    # is at i + 1.

    def initialize
      @mappings = {}
    end

    def store_child_to_parent((child_model, child_id), (parent_model, parent_id))
      mapping = (@mappings[[child_model, parent_model]] ||= [])
      mapping << child_id
      mapping << parent_id
    end

    def length
      @mappings.reduce(0) {|total, (_, mapping)| total + mapping.length / 2}
    end

    def each
      @mappings.each do |(child_model, parent_model), mapping|
        i = 0
        while i < mapping.length
          yield child_model, mapping[i], parent_model, mapping[i + 1], [mapping, i]
          i += 2
        end
      end
    end

    def delete((mapping, idx))
      mapping[idx] = nil
      mapping[idx + 1] = nil
    end

  end


  def self.rap_reference(model, id)
    [model, id]
  end

  def self.rap_load_tree(db, resource_id, subtree_ao_id = nil)
    # Load the entire tree structure into memory.  This includes all
    # ArchivalObjects and their representations.
    record_parents = RecordParents.new

    ao_ids = if subtree_ao_id
               result = []
               ids = [subtree_ao_id]

               while !ids.empty?
                 children = db[:archival_object]
                              .filter(:parent_id => ids)
                              .select(:id)
                              .map {|row| row[:id]}

                 result.concat(ids)
                 ids = children
               end

              # and path to root
               next_id = subtree_ao_id
               while !next_id.nil?
                 parent_id = db[:archival_object]
                              .filter(:id => next_id)
                              .select(:parent_id)
                              .first[:parent_id]

                 result << parent_id if parent_id
                 next_id = parent_id
               end

               result
             else
               []
             end

    # AOs
    ao_query = db[:archival_object]
      .filter(:root_record_id => resource_id)
      .select(:id, :parent_id)

    unless ao_ids.empty?
      ao_query = ao_query.filter(:id => ao_ids)
    end

    ao_query.each do |row|
      if row[:parent_id]
        record_parents.store_child_to_parent(rap_reference(ArchivalObject, row[:id]),
                                             rap_reference(ArchivalObject, row[:parent_id]))
      else
        record_parents.store_child_to_parent(rap_reference(ArchivalObject, row[:id]),
                                             rap_reference(Resource, resource_id))
      end
    end

    # Representations...
    [PhysicalRepresentation, DigitalRepresentation].each do |representation_model|
      representation_table = representation_model.table_name

      query = db[representation_table]
        .filter(Sequel.qualify(representation_table, :resource_id) => resource_id)
        .select(Sequel.qualify(representation_table, :archival_object_id),
                Sequel.qualify(representation_table, :id))

      unless ao_ids.empty?
        query = query.filter(Sequel.qualify(representation_table, :archival_object_id) => ao_ids)
      end

      query.each do |row|
        record_parents.store_child_to_parent(rap_reference(representation_model, row[:id]),
                                             rap_reference(ArchivalObject, row[:archival_object_id]))
      end
    end

    record_parents
  end

  def self.rap_load_connected_raps(db, resource_id)
    # Next we want to gather up all records in the tree with a RAP connected,
    # which might be Resource, ArchivalObject, PhysicalRepresentation or
    # DigitalRepresentation records.
    connected_raps = RapMapping.new(32)

    # Resource RAPs
    db[:rap].filter(:resource_id => resource_id).select(:resource_id, :id).each do |row|
      connected_raps.add(Resource, row[:resource_id], row[:id])
    end

    # AO RAPs
    db[:rap]
      .join(:archival_object, Sequel.qualify(:archival_object, :id) => Sequel.qualify(:rap, :archival_object_id))
      .filter(Sequel.qualify(:archival_object, :root_record_id) => resource_id)
      .select(Sequel.qualify(:rap, :id),
              Sequel.qualify(:rap, :archival_object_id))
      .each do |row|
      connected_raps.add(ArchivalObject, row[:archival_object_id], row[:id])
    end

    # PhysicalRepresentation RAPs
    db[:rap]
      .join(:physical_representation, Sequel.qualify(:physical_representation, :id) => Sequel.qualify(:rap, :physical_representation_id))
      .join(:archival_object, Sequel.qualify(:archival_object, :id) => Sequel.qualify(:physical_representation, :archival_object_id))
      .filter(Sequel.qualify(:archival_object, :root_record_id) => resource_id)
      .select(Sequel.qualify(:rap, :id),
              Sequel.qualify(:rap, :physical_representation_id))
      .each do |row|
      connected_raps.add(PhysicalRepresentation, row[:physical_representation_id], row[:id])
    end

    # DigitalRepresentation RAPs
    db[:rap]
      .join(:digital_representation, Sequel.qualify(:digital_representation, :id) => Sequel.qualify(:rap, :digital_representation_id))
      .join(:archival_object, Sequel.qualify(:archival_object, :id) => Sequel.qualify(:digital_representation, :archival_object_id))
      .filter(Sequel.qualify(:archival_object, :root_record_id) => resource_id)
      .select(Sequel.qualify(:rap, :id),
              Sequel.qualify(:rap, :digital_representation_id))
      .each do |row|
      connected_raps.add(DigitalRepresentation, row[:digital_representation_id], row[:id])
    end

    connected_raps
  end

  def self.drop_already_applied!(db, resource_id, new_raps)
    new_raps.each_chunk(1000) do |record_model, record_ids|
      next unless record_model == ArchivalObject

      db[:rap_applied]
        .filter(Sequel.qualify(:rap_applied, :root_record_id) => resource_id)
        .filter(Sequel.qualify(:rap_applied, :archival_object_id) => record_ids)
        .filter(Sequel.qualify(:rap_applied, :is_active) => 1)
        .select(Sequel.qualify(:rap_applied, :archival_object_id),
                Sequel.qualify(:rap_applied, :rap_id))
        .each do |row|
        if new_raps.rap_for(ArchivalObject, row[:archival_object_id]) == row[:rap_id]
          # Already have this application.  No update needed.
          new_raps.delete(ArchivalObject, row[:archival_object_id])
        end
      end
    end

    new_raps.each_chunk(1000) do |record_model, record_ids|
      next unless record_model == PhysicalRepresentation

      db[:rap_applied]
        .filter(Sequel.qualify(:rap_applied, :physical_representation_id) => record_ids)
        .filter(Sequel.qualify(:rap_applied, :root_record_id) => resource_id,
                Sequel.qualify(:rap_applied, :is_active) => 1)
        .select(Sequel.qualify(:rap_applied, :physical_representation_id),
                Sequel.qualify(:rap_applied, :rap_id))
        .each do |row|
        if new_raps.rap_for(PhysicalRepresentation, row[:physical_representation_id]) == row[:rap_id]
          new_raps.delete(PhysicalRepresentation, row[:physical_representation_id])
        end
      end
    end

    new_raps.each_chunk(1000) do |record_model, record_ids|
      next unless record_model == DigitalRepresentation

      db[:rap_applied]
        .filter(Sequel.qualify(:rap_applied, :digital_representation_id) => record_ids)
        .filter(Sequel.qualify(:rap_applied, :root_record_id) => resource_id,
                Sequel.qualify(:rap_applied, :is_active) => 1)
        .select(Sequel.qualify(:rap_applied, :digital_representation_id),
                Sequel.qualify(:rap_applied, :rap_id))
        .each do |row|
        if new_raps.rap_for(DigitalRepresentation, row[:digital_representation_id]) == row[:rap_id]
          new_raps.delete(DigitalRepresentation, row[:digital_representation_id])
        end
      end
    end

    new_raps
  end

  def self.rap_update_locks_and_mtimes(raps_applied)
    raps_applied.each_chunk(1000) do |record_model, record_ids, _rap_ids|
      record_model.update_mtime_for_ids(record_ids)
    end

    # Find any AOs linked to any updated representations and bump those as well
    archival_object_ids = []
    raps_applied.each_chunk(1000) do |record_model, record_ids, _rap_ids|
      if record_model == ArchivalObject
        archival_object_ids.concat(record_ids)
      else
        # PhysicalRepresentation or DigitalRepresentation
        archival_object_ids.concat(record_model
                                     .filter(:id => record_ids)
                                     .select(:archival_object_id)
                                     .map {|row| row[:archival_object_id]}
                                     .uniq)
      end
    end

    # Reindex their connected AOs too, and bump their lock versions to
    # ensure we get a new history entry.
    ArchivalObject.update_mtime_for_ids(archival_object_ids)
    ArchivalObject.filter(:id => archival_object_ids).update(:lock_version => Sequel.expr(1) + :lock_version)
  end

  def self.calculate_raps_applied(resource_id, record_parents, connected_raps)
    record_raps_applied = RapMapping.new(record_parents.length)
    record_raps_applied.add(Resource, resource_id, connected_raps.rap_for(Resource, resource_id))

    start_time = Time.now
    processed = 0

    # Trivial case: records with a RAP attached have that RAP applied.
    record_parents.each do |child_model, child_id, parent_model, parent_id, delete_key|
      if rap_id = connected_raps.rap_for(child_model, child_id)
        record_raps_applied.add(child_model, child_id, rap_id)

        processed += 1
        record_parents.delete(delete_key)
      end
    end

    # Everyone else needs a tree search
    while processed < record_parents.length
      old_processed = processed

      record_parents.each do |child_model, child_id, parent_model, parent_id, delete_key|
        # We've already processed this entry
        next if child_id.nil?

        # If the parent has a RAP, apply it to the child
        if rap_id = record_raps_applied.rap_for(parent_model, parent_id)
          record_raps_applied.add(child_model, child_id, rap_id)

          processed += 1
          record_parents.delete(delete_key)
        end
      end

      raise "RAP deadlock detected after processing %d records" % [processed] if old_processed == processed
    end

    record_raps_applied
  end

  def self.propagate_raps!(resource_id, subtree_ao_id = nil)
    default_rap_id = RAP.get_default_id

    DB.open do |db|
      start_time = Time.now

      record_parents = rap_load_tree(db, resource_id, subtree_ao_id)
      connected_raps = rap_load_connected_raps(db, resource_id)

      # If the resource doesn't have a RAP, it takes the system default
      if connected_raps.rap_for(Resource, resource_id).nil?
        connected_raps.add(Resource, resource_id, default_rap_id)
      end

      Log.info("Resource: %d" % [resource_id])
      Log.info("Tree size: %d" % [record_parents.length])
      Log.info("Connected RAPs: %d" % [connected_raps.length])

      Log.info("Loaded tree structure and existing RAPs in %d ms" % [((Time.now.to_f - start_time.to_f) * 1000).to_i])
      start_time = Time.now

      record_raps_applied = calculate_raps_applied(resource_id, record_parents, connected_raps)

      Log.info("RAPs calculated in %d ms" % [((Time.now.to_f - start_time.to_f) * 1000).to_i])

      record_raps_applied.delete(Resource, resource_id)

      begin
        drop_already_applied!(db, resource_id, record_raps_applied)
      rescue
        Log.exception($!)
      end

      ## Apply any remaining changes

      # Any rows referencing our records are now inactive
      record_raps_applied.each_chunk(1000) do |record_model, record_ids, _rap_ids|
        backlink_col = :"#{record_model.table_name}_id"
        db[:rap_applied]
          .filter(backlink_col => record_ids)
          .update(:is_active => 0)
      end

      # Insert our rows
      now = java.sql.Timestamp.new(java.util.Date.new.getTime)

      updated_count = 0

      # Dropping to JDBC here to keep memory usage under control while
      # inserting.  Sequel builds up SQL strings that end up being large when
      # there are millions of rows.
      db.transaction do |jdbc_conn|
        record_raps_applied.each_chunk(1000) do |record_model, record_ids, rap_ids|
          backlink_col = "#{record_model.table_name}_id"
          ps = jdbc_conn.prepare_statement("insert into rap_applied (date_applied, rap_id, #{backlink_col}, is_active, root_record_id) values (?, ?, ?, ?, ?)")

          record_ids.zip(rap_ids).each do |record_id, rap_id|
            ps.setTimestamp(1, now)
            ps.setInt(2, rap_id)
            ps.setInt(3, record_id)
            ps.setInt(4, 1)
            ps.setInt(5, resource_id)

            ps.addBatch
            updated_count += 1
          end

          ps.executeBatch
        end
      end

      rap_update_locks_and_mtimes(record_raps_applied)

      updated_count
    end
  end


  def self.rap_needs_propagate(resource_id, subtree_ao_id = nil)
    if RequestContext.active? && RequestContext.get(:deferred_rap_propagation_resource_ids)
      # Defer propagating.  Used for things like batch import.
      RequestContext.get(:deferred_rap_propagation_resource_ids) << resource_id
    else
      # Propagate immediately
      self.propagate_raps!(resource_id, subtree_ao_id)
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
          "item_count" => 0,
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
          "item_count" => 0,
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
          "item_count" => 0,
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
          "item_count" => 0,
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
          "item_count" => 0,
          "digital_representation_count" => 0,
          "physical_representation_count" => 0,
        }
      end

      db[:rap_applied]
        .join(:archival_object, Sequel.qualify(:archival_object, :id) => Sequel.qualify(:rap_applied, :archival_object_id))
        .filter(Sequel.qualify(:archival_object, :root_record_id) => self.id)
        .filter(:rap_id => rap_id_to_summary.keys)
        .filter(:is_active => 1)
        .filter(Sequel.~(:archival_object_id => nil))
        .group_and_count(:rap_id)
        .each do |row|
        rap_id_to_summary.fetch(row[:rap_id])["item_count"] = row[:count]
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

