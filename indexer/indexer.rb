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
  @@record_types << :batch

  add_attribute_to_resolve('container')
  add_attribute_to_resolve('container::container_locations')
  add_attribute_to_resolve('responsible_agency')

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

        doc['top_container_title_u_sstr'] = record.dig('record', 'container', '_resolved', 'display_string')
        doc['top_container_location_u_sstr'] = record.dig('record', 'container', '_resolved', 'current_location')

        home_location = (record.dig('record', 'container', '_resolved', 'container_locations') || []).find {|location|
          location['status'] == 'current'
        }

        if home_location
          doc['top_container_home_location_u_sstr'] = home_location['_resolved']['title']
        end

        doc['representation_format_u_sstr'] = record.dig('record', 'format')

        doc['controlling_record_u_sstr'] = record['record']['controlling_record']['ref']
        doc['responsible_agency_u_sstr'] = record['record']['responsible_agency']['ref']
        doc['frequency_of_use_u_sint'] = record['record']['frequency_of_use']
        doc['file_issue_allowed_u_sbool'] = [record['record']['file_issue_allowed'] && !record['record']['deaccessioned']]

        doc['significance_u_sstr'] = record['record']['significance']

        doc['responsible_agency_title_u_sstr'] = record.dig('record', 'responsible_agency', '_resolved', 'display_name', 'sort_name')
        doc['responsible_agency_qsa_id_u_sstr'] = record.dig('record', 'responsible_agency', '_resolved', 'qsa_id_prefixed')

        doc['controlling_record_qsa_id_u_sint'] = record['record']['controlling_record']['qsa_id']
        doc['controlling_record_qsa_id_u_sort'] = record['record']['controlling_record']['qsa_id'].to_s.rjust(9, '0')
        doc['controlling_record_qsa_id_u_ssort'] = record['record']['controlling_record']['qsa_id_prefixed']

        doc['controlling_record_begin_date_u_ssort'] = record.dig('record', 'controlling_record', 'begin_date')
        doc['controlling_record_end_date_u_ssort'] = record.dig('record', 'controlling_record', 'end_date')

        doc['controlling_record_series_qsa_id_u_sint'] = record['record']['controlling_record_series']['qsa_id']
        doc['controlling_record_series_qsa_id_u_sort'] = record['record']['controlling_record_series']['qsa_id'].to_s.rjust(9, '0')
        doc['controlling_record_series_qsa_id_u_ssort'] = record['record']['controlling_record_series']['qsa_id_prefixed']

        doc['conservation_awaiting_treatment_u_sbool'] = Array(record['record']['conservation_treatments']).any?{|t| t['status'] == 'awaiting_treatment'}
        doc['conservation_treatment_in_progress_u_sbool'] = Array(record['record']['conservation_treatments']).any?{|t| t['status'] == 'in_progress'}
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
        doc['conservation_request_status_u_ssort'] = record['record']['status']
        doc['conservation_request_reason_requested_u_ssort'] = record['record']['reason_requested']

        doc['conservation_request_date_of_request_u_sstr'] = record['record']['date_of_request']
        doc['conservation_request_date_of_request_u_ssortdate'] = RuncornIndexing.nullable_date_to_time(record['record']['date_of_request'])

        doc['conservation_request_date_required_by_u_sstr'] = record['record']['date_required_by']
        doc['conservation_request_date_required_by_u_ssortdate'] = RuncornIndexing.nullable_date_to_time(record['record']['date_required_by'])
      end

      # Representations will have the URI of the conservation request(s) they're
      # attached to
      if record['record']['conservation_requests']
        doc['conservation_request_attached_u_sstr'] = record['record']['conservation_requests'].map {|ref| ref['ref']}
      end

    end


    indexer.add_document_prepare_hook do |doc, record|
      if doc['primary_type'] == 'batch'
        doc['title'] = record['record']['display_string']
        doc['batch_status_u_ssort'] = record['record']['status']
        if record['record']['note']
          doc['note_summary_u_ssort'] = record['record']['note'][0,60]
          doc['note_summary_u_ssort'] += ' ...' if record['record']['note'].length > 60
        else
          doc['note_summary_u_ssort'] = '-- no note --'
        end
      end
    end


    indexer.add_document_prepare_hook {|doc, record|
      if doc['primary_type'] == 'assessment'
        vals = JSONModel.enum_values('runcorn_treatment_priority')
        pri = record['record']['treatment_priority']
        doc['assessment_treatment_priority_u_sort'] = ((vals.index(pri) || -1) + 1).to_s
        doc['assessment_treatment_priority_u_ssort'] = pri
      end
    }


    indexer.add_document_prepare_hook do |doc, record|
      if record['record'].has_key?('qsa_id')
        doc['qsa_id_u_sint'] = record['record']['qsa_id']
        doc['qsa_id_u_sort'] = record['record']['qsa_id'].to_s.rjust(9, '0')
        doc['qsa_id_u_ssort'] = record['record']['qsa_id_prefixed']
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
