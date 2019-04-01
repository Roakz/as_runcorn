class IndexerCommon
  @@record_types << :physical_representation
  @@record_types << :digital_representation

  add_indexer_initialize_hook do |indexer|

    indexer.add_document_prepare_hook {|doc, record|
      if doc['primary_type'] == 'physical_representation'
        doc['title'] = record['record']['display_string']
        doc['representation_intended_use_u_sstr'] = record['record']['intended_use']
        doc['top_container_uri_u_sstr'] = ASUtils.wrap(record['record']['containers']).map{|container| container['top_container']['ref']}
      end
    }

    indexer.add_document_prepare_hook {|doc, record|
      if doc['primary_type'] == 'digital_representation'
        doc['title'] = record['record']['display_string']
        doc['representation_intended_use_u_sstr'] = record['record']['intended_use']
      end
    }

    indexer.add_document_prepare_hook do |doc, record|
      if record['record'].has_key?('qsa_id')
        doc['qsa_id__u_sint'] = record['record']['qsa_id']
      end
    end

    indexer.add_document_prepare_hook {|doc, record|
      if ['resource', 'archival_object'].include?(doc['primary_type'])
        summary = [
          [record['record']['physical_representations_count'], "#{record['record']['physical_representations_count']} physical representations"],
          [record['record']['digital_representations_count'], "#{record['record']['digital_representations_count']} digital representations"]
        ].select{|counts| counts[0] > 0}.map(&:last).join(', ')

        doc['title'] += " - #{summary}" unless summary.empty?
      end
    }
  end
end
