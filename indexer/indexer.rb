class RuncornIndexing

  def self.nullable_date_to_time(s)
    return nil if s.nil?

    "#{s}T00:00:00Z"
  end

end

class IndexerCommon
  @@record_types << :physical_representation
  @@record_types << :digital_representation
  @@record_types << :chargeable_service
  @@record_types << :chargeable_item
  @@record_types << :conservation_request

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
        doc['top_container_uri_u_sstr'] = record['record'].fetch('container', {}).fetch('ref', nil)
        doc['controlling_record_u_sstr'] = record['record']['controlling_record']['ref']
        doc['file_issue_allowed_u_sbool'] = [record['record']['file_issue_allowed'] && !record['record']['deaccessioned']]
      end
    }

    indexer.add_document_prepare_hook {|doc, record|
      if doc['primary_type'] == 'digital_representation'
        doc['title'] = record['record']['display_string']
        doc['representation_intended_use_u_sstr'] = record['record']['intended_use']
        doc['controlling_record_u_sstr'] = record['record']['controlling_record']['ref']
        doc['file_issue_allowed_u_sbool'] = [record['record']['file_issue_allowed'] && !record['record']['deaccessioned']]
      end
    }

    indexer.add_document_prepare_hook do |doc, record|
      if record['record']['rap_expiration']
        doc['rap_existence_end_date_u_sdate'] = RuncornIndexing.nullable_date_to_time(record['record']['rap_expiration']['existence_end_date'])
        doc['rap_expiry_date_u_sstr'] = record['record']['rap_expiration']['expiry_date']
        doc['rap_expiry_date_sort_u_ssortdate'] = RuncornIndexing.nullable_date_to_time(record['record']['rap_expiration']['expiry_date'])
        doc['rap_expired_u_sbool'] = record['record']['rap_expiration']['expired']
      end
    end

    indexer.add_document_prepare_hook do |doc, record|
      if record['record']['rap_expiration']
        doc['rap_existence_end_date_u_sdate'] = RuncornIndexing.nullable_date_to_time(record['record']['rap_expiration']['existence_end_date'])
        doc['rap_expiry_date_u_sstr'] = record['record']['rap_expiration']['expiry_date']
        doc['rap_expiry_date_sort_u_ssortdate'] = RuncornIndexing.nullable_date_to_time(record['record']['rap_expiration']['expiry_date'])
        doc['rap_expired_u_sbool'] = record['record']['rap_expiration']['expired']
      end

      if record['record']['rap_applied']
        applied = record['record']['rap_applied']

        doc['rap_open_access_metadata_u_ssort'] = applied['open_access_metadata'] ? 'yes' : 'no'
        doc['rap_access_status_u_ssort'] = applied['access_status']
        doc['rap_access_category_u_ssort'] = applied['access_category']
      end

    end



    indexer.add_document_prepare_hook {|doc, record|
      if doc['primary_type'] == 'chargeable_item'
        doc['title'] = record['record']['name']
      end
    }

    indexer.add_document_prepare_hook do |doc, record|
      if doc['primary_type'] == 'conservation_request'
        doc['title'] = record['record']['display_string']
      end

      # Representations will have the URI of the conservation request(s) they're
      # attached to
      if record['record']['conservation_requests']
        doc['conservation_request_attached_u_sstr'] = record['record']['conservation_requests'].map {|ref| ref['ref']}
      end

    end

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
