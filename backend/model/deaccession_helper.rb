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
        result << ['resource', db[:resource].filter(:id => parsed_uri[:id]).select(:title).map{|row| row[:title]}.first]

        if (count = db[:archival_object].filter(:root_record_id => parsed_uri[:id])).count > 100
          result << ['archival_object', "%s Archival Objects" % count.to_s]
          all_archival_object_ids = db[:archival_object].filter(:root_record_id => parsed_uri[:id]).select(:id).map{|row| row[:id]}
        else
          db[:archival_object]
            .filter(:root_record_id => parsed_uri[:id])
            .order(:position)
            .select(:id, :display_string)
            .each do |row|
            all_archival_object_ids << row[:id]
            result << ['archival_object', row[:display_string]]
          end
        end
      elsif parsed_uri[:type] == 'archival_object'
        result << ['archival_object', db[:archival_object].filter(:id => parsed_uri[:id]).select(:display_string).map{|row| row[:display_string]}.first]
        all_archival_object_ids << parsed_uri[:id]
        to_process = [parsed_uri[:id]]
        while(!to_process.empty?) do
          next_batch = [] 

          db[:archival_object]
          .filter(:parent_id => to_process)
          .select(:id, :display_string)
          .each do |row|
            all_archival_object_ids << row[:id]
            result << ['archival_object', row[:display_string]]
            next_batch << row[:id]
          end

          to_process = next_batch
        end
      end

      if all_archival_object_ids.length > 100
        result << ['digital_representation', "%s Digital Representations" % db[:digital_representation].filter(:archival_object_id => all_archival_object_ids).count]
        result << ['physical_representation', "%s Physical Representations" % db[:physical_representation].filter(:archival_object_id => all_archival_object_ids).count]
      elsif all_archival_object_ids.length > 0
        db[:digital_representation]
          .filter(:archival_object_id => all_archival_object_ids)
          .select(:title)
          .each do |row|
          result << ['digital_representation', row[:title]]
        end
        db[:physical_representation]
        .filter(:archival_object_id => all_archival_object_ids)
        .select(:title)
        .each do |row|
          result << ['physical_representation', row[:title]]
        end
      end
    end

    result
  end
end