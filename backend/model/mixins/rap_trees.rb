module RAPTrees

  def set_parent_and_position(*)
    # Note: When dropping multiple records this will currently run the
    # propagation process multiple times.  Not ideal, but there's no obvious
    # place to put a hook.  If this becomes a performance issue we need
    # ArchivesSpace to call us back when a drag/drop event has been processed
    # (prior to committing the transaction).
    result = super

    Resource[self.root_record_id].propagate_raps!

    result
  end

end
