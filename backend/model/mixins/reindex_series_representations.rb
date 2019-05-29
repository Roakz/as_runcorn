module ReindexSeriesRepresentations

  def reindex_representations!
    DB.open do |db|
      id_set = db[:archival_object].filter(:root_record_id => self.id).select(:id)

      [:physical_representation, :digital_representation].each do |tbl|
        db[tbl].filter(:archival_object_id => id_set).update(:system_mtime => Time.now)
      end
    end
  end

  def update_from_json(json, opts = {}, apply_nested_records = true)
    super

    reindex_representations!
  end

end
