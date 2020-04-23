module ControllingAgencyPublication

  # The publish value of the agency affects any records controlled by the
  # agency, such that when unpublishing the agency we need ensure those records
  # are reindexed and subsequently deleted removed from the public index
  def update_from_json(json, opts = {}, apply_nested_records = true)
    unpublishing_the_agency = (self.publish == 1 && !json['publish'])

    result = super

    if unpublishing_the_agency
      reindex_published_controlled_records
    end

    result
  end

  private

  def reindex_published_controlled_records
    now = Time.now

    DB.open do |db|
      resource_ids = db[:series_system_rlshp]
                       .join(:resource, Sequel.qualify(:resource, :id) => Sequel.qualify(:series_system_rlshp, :resource_id_0))
                       .filter(Sequel.qualify(:series_system_rlshp, :jsonmodel_type) => 'series_system_agent_record_ownership_relationship')
                       .filter(Sequel.qualify(:series_system_rlshp, :end_date) => nil)
                       .filter(Sequel.qualify(:series_system_rlshp, :agent_corporate_entity_id_0) => self.id)
                       .filter(Sequel.qualify(:resource, :publish) => 1)
                       .select(Sequel.qualify(:resource, :id))
                       .map{|row| row[:id]}

      db[:resource]
        .filter(:id => resource_ids)
        .update(:system_mtime => now)

      db[:archival_object]
        .filter(:root_record_id => resource_ids)
        .filter(:publish => 1)
        .update(:system_mtime => now)

      db[:physical_representation]
        .filter(:resource_id => resource_ids)
        .filter(:publish => 1)
        .update(:system_mtime => now)

      db[:digital_representation]
        .filter(:resource_id => resource_ids)
        .filter(:publish => 1)
        .update(:system_mtime => now)

      ao_ids_to_process = db[:series_system_rlshp]
                            .join(:archival_object, Sequel.qualify(:archival_object, :id) => Sequel.qualify(:series_system_rlshp, :archival_object_id_0))
                            .filter(Sequel.qualify(:series_system_rlshp, :jsonmodel_type) => 'series_system_agent_record_ownership_relationship')
                            .filter(Sequel.qualify(:series_system_rlshp, :end_date) => nil)
                            .filter(Sequel.qualify(:series_system_rlshp, :agent_corporate_entity_id_0) => self.id)
                            .filter(Sequel.qualify(:archival_object, :publish) => 1)
                            .select(Sequel.qualify(:archival_object, :id))
                            .map{|row| row[:id]}

      while(ao_ids_to_process.length > 0)
        db[:archival_object]
          .filter(:id => ao_ids_to_process)
          .update(:system_mtime => now)

        db[:physical_representation]
          .filter(:archival_object_id => ao_ids_to_process)
          .update(:system_mtime => now)

        db[:digital_representation]
          .filter(:archival_object_id => ao_ids_to_process)
          .update(:system_mtime => now)

        ao_ids_to_process = db[:archival_object]
                              .filter(:parent_id => ao_ids_to_process)
                              .filter(:publish => 1)
                              .select(:id)
                              .map{|row| row[:id]}
      end
    end
  end
end