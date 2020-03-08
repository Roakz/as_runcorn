module ReindexSeriesRepresentations

  def reindex_representations!
    DB.open do |db|
      now = Time.now

      [:physical_representation, :digital_representation].each do |tbl|
        db[:archival_object]
          .join(tbl,
                Sequel.qualify(tbl, :archival_object_id) => Sequel.qualify(:archival_object, :id))
          .filter(Sequel.qualify(:archival_object, :root_record_id) => self.id)
          .update(Sequel.qualify(tbl, :system_mtime) => now)
      end
    end
  end

  def update_from_json(json, opts = {}, apply_nested_records = true)
    result = super

    unless ASUtils.migration_mode?
      reindex_representations!
    end

    result
  end

end
