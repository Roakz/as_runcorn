class DeaccessionHelper

  def self.affected_records(uri)
    parsed_uri = JSONModel.parse_reference(uri)

    if parsed_uri[:repository] && JSONModel.parse_reference(parsed_uri[:repository])[:id] != RequestContext.get(:repo_id)
      raise "Repository mismatch"
    end

    result = []

    DB.open do |db|
      all_archival_object_ids = []

      if parsed_uri[:type] == 'resource'
        resource = db[:resource].filter(:id => parsed_uri[:id]).select(:title, :qsa_id).first
        result << ['resource', resource[:title], resource[:qsa_id]]

        db[:archival_object]
          .filter(:root_record_id => parsed_uri[:id])
          .order(:position)
          .select(:id, :display_string, :qsa_id)
          .each do |row|
          all_archival_object_ids << row[:id]
          result << ['archival_object', row[:display_string], row[:qsa_id]]
        end
      elsif parsed_uri[:type] == 'archival_object'
        archival_object = db[:archival_object].filter(:id => parsed_uri[:id]).select(:display_string, :qsa_id).first
        result << ['archival_object', archival_object[:display_string], archival_object[:qsa_id]]
        all_archival_object_ids << parsed_uri[:id]
        to_process = [parsed_uri[:id]]
        while(!to_process.empty?) do
          next_batch = []

          db[:archival_object]
          .filter(:parent_id => to_process)
          .select(:id, :display_string, :qsa_id)
          .each do |row|
            all_archival_object_ids << row[:id]
            result << ['archival_object', row[:display_string], row[:qsa_id]]
            next_batch << row[:id]
          end

          to_process = next_batch
        end
      elsif parsed_uri[:type] == 'digital_representation'
        rep = db[:digital_representation].filter(:id => parsed_uri[:id]).select(:title, :qsa_id).first
        result << ['digital_representation', rep[:title], rep[:qsa_id]]
      elsif parsed_uri[:type] == 'physical_representation'
        rep = db[:physical_representation].filter(:id => parsed_uri[:id]).select(:title, :qsa_id).first
        result << ['physical_representation', rep[:title], rep[:qsa_id]]
      else
        raise "Not supported: #{uri}"
      end

      if all_archival_object_ids.length > 0
        db[:digital_representation]
          .filter(:archival_object_id => all_archival_object_ids)
          .select(:title, :qsa_id)
          .each do |row|
          result << ['digital_representation', row[:title], row[:qsa_id]]
        end
        db[:physical_representation]
        .filter(:archival_object_id => all_archival_object_ids)
        .select(:title, :qsa_id)
        .each do |row|
          result << ['physical_representation', row[:title], row[:qsa_id]]
        end
      end
    end

    result
  end
end