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
  @@record_types << :item_use

  add_attribute_to_resolve('container')
  add_attribute_to_resolve('container::container_locations')
  add_attribute_to_resolve('responsible_agency')
  add_attribute_to_resolve('actions')

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

  def self.split_qsa_id(s)
    s.scan(/([^\d]+)?(\d+)/)[0]
  end

  # include the prefix in the sort string so that different models sort separately
  def self.sort_value_for_qsa_id(id)
    (prefix, number) = IndexerCommon.split_qsa_id(id)
    prefix.to_s.ljust(9, '0') + number.to_s.rjust(9,'0')
  end

  add_indexer_initialize_hook do |indexer|
    require_relative '../common/qsa_id'
    QSAId.mode(:indexer)
    require_relative '../common/qsa_id_registrations'

    indexer.add_document_prepare_hook {|doc, record|
      doc['deaccessioned_u_sbool'] = !!record['record']['deaccessioned']

      if record['record']['conservation_treatments']
        doc['conservation_treatment_u_stext'] = ASUtils.extract_nested_strings(record['record']['conservation_treatments']).join(" ")
      end

      if record['record']['current_location']
        doc['current_location_u_sstr'] = record['record']['current_location']
      end

      if doc['primary_type'] == 'top_container'
        doc['top_container_identifier_u_ssort'] = SearchUtils.pad_top_container_identifier(record['record']['indicator'])
      end

      if record['record']['agency_assigned_id']
        doc['agency_assigned_id_u_stext'] = record['record']['agency_assigned_id']
        doc['agency_assigned_id_u_sort'] = record['record']['agency_assigned_id']
      end

      unless record['record']['archivist_approved'].nil?
        doc['archivist_approved_u_sbool'] = !!record['record']['archivist_approved']
      end

      if doc['primary_type'] == 'physical_representation'
        doc['title'] = record['record']['display_string']
        doc['representation_intended_use_u_sstr'] = record['record']['intended_use']

        doc['top_container_uri_u_sstr'] = record['record'].fetch('container', {}).fetch('ref', nil)

        top_container_indicator = record['record'].dig('container', '_resolved', 'indicator')
        doc['top_container_identifier_u_ssort'] = SearchUtils.pad_top_container_identifier(top_container_indicator)


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
        doc['file_issue_allowed_u_sbool'] = [(record['record']['file_issue_allowed'] == 'allowed_true') && !record['record']['deaccessioned']]

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

        doc['conservation_treatments_applied_u_sstr'] = Array(record['record']['conservation_treatments'])
          .map{|ct| Array(ct['treatments']).map{|t| t['label']}}.flatten.uniq
      end
    }

    indexer.add_document_prepare_hook {|doc, record|
      if doc['primary_type'] == 'digital_representation'
        doc['title'] = record['record']['display_string']
        doc['representation_intended_use_u_sstr'] = record['record']['intended_use']
        doc['controlling_record_u_sstr'] = record['record']['controlling_record']['ref']
        doc['file_issue_allowed_u_sbool'] = [(record['record']['file_issue_allowed'] == 'allowed_true') && !record['record']['deaccessioned']]

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

      if record['record']['rap_access_status'] && !doc['rap_access_status_u_ssort']
        doc['rap_access_status_u_ssort'] = record['record']['rap_access_status']
      end

      unless doc['rap_access_status_u_ssort'].nil?
        doc['rap_is_open_access_u_sbool'] = doc['rap_access_status_u_ssort'] == 'Open Access'
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

      if record['record']['date_of_request']
        doc['date_start_u_ssort'] = (parsed = DateParse.date_parse_down(record['record']['date_of_request'])) ? parsed.iso8601 : nil
        doc['date_start_u_sstr'] = record['record']['date_of_request']
      end

      if record['record']['date_required_by']
        doc['date_end_u_ssort'] = (parsed = DateParse.date_parse_up(record['record']['date_required_by'])) ? parsed.iso8601 : nil
        doc['date_end_u_sstr'] = record['record']['date_required_by']
      end
    end


    indexer.add_document_prepare_hook do |doc, record|
      if doc['primary_type'] == 'batch'
        doc['title'] = record['record']['display_string']
        doc['batch_status_u_ssort'] = record['record']['status']
        if record['record']['note']
          doc['batch_note_summary_u_ssort'] = record['record']['note'][0,60]
          doc['batch_note_summary_u_ssort'] += ' ...' if record['record']['note'].length > 60
        else
          doc['batch_note_summary_u_ssort'] = '-- no note --'
        end

        if record['record']['actions'].empty?
          doc['batch_latest_action_u_ssort'] = 'no_action'
        else
          doc['batch_latest_action_u_ssort'] = record['record']['actions'].last['_resolved']['action_type']
        end
      end
    end


    indexer.add_document_prepare_hook {|doc, record|
      if doc['primary_type'] == 'assessment'
        vals = JSONModel.enum_values('runcorn_treatment_priority')
        pri = record['record']['treatment_priority']
        doc['assessment_treatment_priority_u_sort'] = ((vals.index(pri) || -1) + 1).to_s
        doc['assessment_treatment_priority_u_ssort'] = pri


        doc['date_start_u_ssort'] = record['record']['survey_begin']
        doc['date_start_u_sstr'] = record['record']['survey_begin']
        doc['date_end_u_ssort'] = record['record']['survey_end']
        doc['date_end_u_sstr'] = record['record']['survey_end']
      end
    }


    indexer.add_document_prepare_hook do |doc, record|
      if record['record'].has_key?('qsa_id')
        doc['qsa_id_u_sint'] = record['record']['qsa_id']
        doc['qsa_id_u_stext'] = [record['record']['qsa_id']]

        if record['record']['qsa_id_prefixed']
          doc['qsa_id_u_sort'] = IndexerCommon.sort_value_for_qsa_id(record['record']['qsa_id_prefixed'])
          doc['qsa_id_u_ssort'] = record['record']['qsa_id_prefixed']
          doc['qsa_id_u_stext'] << record['record']['qsa_id_prefixed']
        end
      else
        doc['qsa_id_u_sort'] = IndexerCommon.sort_value_for_qsa_id(JSONModel::JSONModel(doc['primary_type'].intern).id_for(record['record']['uri']).to_s)
      end
    end

    indexer.add_document_prepare_hook {|doc, record|
      if ['resource', 'archival_object'].include?(doc['primary_type'])
        counts = []

        if doc['primary_type'] == 'resource'
          counts << [record['record']['items_count'], "#{record['record']['items_count']} items"]
        end

        if record['record']['physical_representations_count']
          counts << [record['record']['physical_representations_count'], "#{record['record']['physical_representations_count']} physical representations"]
        end

        if record['record']['digital_representations_count']
          counts << [record['record']['digital_representations_count'], "#{record['record']['digital_representations_count']} digital representations"]
        end

        summary = counts.map{|count, label| label if count > 0}.compact.join(', ')

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

    indexer.add_document_prepare_hook do |doc, record|
      if doc['primary_type'] == 'item_use'
        rep = record['record'].fetch('representation', {})

        doc['title'] = record['record']['display_string']
        doc['item_use_item_uri_u_sstr'] = rep['ref']
        doc['item_qsa_id_u_sort'] = IndexerCommon.sort_value_for_qsa_id(rep['qsa_id'])
        doc['item_qsa_id_u_ssort'] = rep['qsa_id']
        doc['use_qsa_id_u_sort'] = IndexerCommon.sort_value_for_qsa_id(record['record']['use_identifier'])
        doc['use_qsa_id_u_ssort'] = record['record']['use_identifier']
        doc['item_use_status_u_ssort'] = record['record']['status']
        doc['item_use_type_u_ssort'] = record['record']['item_use_type']
        doc['item_use_start_date_u_ssort'] = record['record']['start_date']
        doc['item_use_end_date_u_ssort'] = record['record']['end_date']
        doc['item_use_used_by_u_ssort'] = record['record']['used_by']

        doc['date_start_u_ssort'] = record['record']['start_date']
        doc['date_start_u_sstr'] = record['record']['start_date']
        doc['date_end_u_ssort'] = record['record']['end_date']
        doc['date_end_u_sstr'] = record['record']['end_date']
      end
    end

    indexer.add_document_prepare_hook do |doc, record|
      if record['record'].has_key?('archivist_approved')
        doc['archivist_approved_u_sbool'] = record['record']['archivist_approved']
      end
    end

    indexer.add_document_prepare_hook do |doc, record|
      date = if Array(record['record']['dates']).length > 0
               # Resources, AOs
               Array(record['record']['dates']).first
             elsif record['record']['date']
               # Mandates, functions
               record['record']['date']
             elsif Array(record['record']['dates_of_existence']).length > 0
               # Agencies
               Array(record['record']['dates_of_existence']).first
             elsif ['physical_representation', 'digital_representation'].include?(record['record']['jsonmodel_type'])
               {
                'begin' => record.dig('record', 'controlling_record', 'begin_date'),
                'end' => record.dig('record', 'controlling_record', 'end_date'),
               }
             else
               nil
             end
      if date
        doc['date_start_u_ssort'] = DateRangeQuery.date_pad_start(date['begin'])
        doc['date_end_u_ssort'] = DateRangeQuery.date_pad_end(date['end'])
        doc['date_start_u_sstr'] = date['begin']
        doc['date_start_certainty_u_sstr'] = date['certainty']
        doc['date_end_u_sstr'] = date['end']
        doc['date_end_certainty_u_sstr'] = date['certainty_end']
      end
    end

    indexer.add_document_prepare_hook do |doc, record|
      if record['record'].has_key?('within')
        doc['runcorn_set_u_ustr'] = record['record']['within'].map{|qsa_id| [qsa_id.upcase, qsa_id.downcase]}.flatten
      end
    end
  end
end
