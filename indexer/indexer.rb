class IndexerCommon
  @@record_types << :physical_representation
  @@record_types << :digital_representation

  def self.build_recent_agency_filter(recent_agencies)
    result = []

    recent_agencies.each do |ref|
      agency_uri = ref['ref']

      date = Date.parse(ref['end_date'])

      90.times do |i|
        result << agency_uri + "_" + (date + i).strftime('%Y-%m-%d')
      end
    end

    result
  end


  add_indexer_initialize_hook do |indexer|
    require_relative '../common/qsa_id'
    QSAId.mode(:indexer)
    require_relative '../common/qsa_id_registrations'

    indexer.add_document_prepare_hook {|doc, record|
      if doc['primary_type'] == 'physical_representation'
        doc['title'] = record['record']['display_string']
        doc['representation_intended_use_u_sstr'] = record['record']['intended_use']
        doc['top_container_uri_u_sstr'] = ASUtils.wrap(record['record']['containers']).map{|container| container['top_container']['ref']}
        doc['controlling_record_u_sstr'] = record['record']['controlling_record']['ref']
        doc['file_issue_allowed_u_sbool'] = [record['record']['file_issue_allowed']]
      end
    }

    indexer.add_document_prepare_hook {|doc, record|
      if doc['primary_type'] == 'digital_representation'
        doc['title'] = record['record']['display_string']
        doc['representation_intended_use_u_sstr'] = record['record']['intended_use']
        doc['controlling_record_u_sstr'] = record['record']['controlling_record']['ref']
        doc['file_issue_allowed_u_sbool'] = [record['record']['file_issue_allowed']]
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

    indexer.add_document_prepare_hook do |doc, record|
      if ['agent_corporate_entity'].include?(record['record']['jsonmodel_type'])
        doc['agency_category_u_sstr'] = record['record']['agency_category']
      end
    end

    indexer.add_document_prepare_hook do |doc, record|
      jsonmodel = record['record']

      if jsonmodel.has_key?('responsible_agency')
        doc['responsible_agency_u_ustr'] = jsonmodel['responsible_agency']['ref']
      end

      if jsonmodel.has_key?('recent_responsible_agencies')
        doc['recent_responsible_agency_filter_u_ustr'] =
          IndexerCommon.build_recent_agency_filter(jsonmodel['recent_responsible_agencies'])
      end
    end

  end
end
