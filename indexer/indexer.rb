class IndexerCommon
  @@record_types << :physical_representation

  add_indexer_initialize_hook do |indexer|

    indexer.add_document_prepare_hook {|doc, record|
      if doc['primary_type'] == 'physical_representation'
        doc['title'] = record['record']['display_string'] 
      end
    }

  end

end
