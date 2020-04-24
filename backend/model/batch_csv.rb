require 'csv'

class BatchCSV

  HEADERS = [
             'Record Type',
             'ID',
             'Title',
             'Start Date',
             'Certainty',
             'End Date',
             'Certainty',
             'Found In',
             'Published?',
             'Archivist Approved?',
             'Accessioned Status',
             'Category/ Format',
             'Associated Record ID',
             'Top Container',
             'Frequency of use',
             'RAP Status',
             'RAP Expiry Date',
             'Access Category',
             'Years',
             'RAP Publish Details?',
             'RAP is inherited?',
             'Significance',
             'Significance Inherited?',
             'Sensitivity label',
             'Agency Control No.',
             'Previous System Location',
             'Home Location',
             'Current Location',
             'Availability',
             'Responsible Agency ID',
             'Responsible Agency Name',
             'Responsible Agency Inherited?',
            ]

  def self.for_refs(many_many_refs)
    new(many_many_refs)
  end

  def initialize(refs)
    @refs = refs
  end

  def each_chunk(&block)
    block.call(HEADERS.to_csv)

    @refs.each_slice(AppConfig[:max_page_size]) do |slice|
      query = "{!terms f=id}" + slice.join(',')

      results = Search.search({
                                :q => query,
                                :page => 1,
                                :page_size => AppConfig[:max_page_size],
                              }, RequestContext.get(:repo_id))

      block.call(
        results['results'].map {|result|
          json = ASUtils.json_parse(result['json'])
          [
           I18n.t(result['primary_type'] + '._singular'),
           result['qsa_id_u_ssort'],
           json.fetch('title', result['title']),
           date_for(result, json, :begin),
           date_for(result, json, :begin, :certainty),
           date_for(result, json, :end),
           date_for(result, json, :end, :certainty),
           series_for(result, json),
           boolean_for('publish', json),
           boolean_for('archivist_approved', json),
           enum_for('runcorn_accessioned_status', json['accessioned_status']),
           format_for(result, json),
           parent_for(result, json),
           container_for(result, json),
           result.dig('frequency_of_use_u_sint', 0),
           result['rap_access_status_u_ssort'],
           result.dig('rap_expiry_date_u_sstr', 0),
           json.dig('rap_applied', 'access_category'),
           json.dig('rap_applied', 'years'),
           json.dig('rap_applied', 'open_access_metadata').nil? ? '' : (json.dig('rap_applied', 'open_access_metadata') ? 'Y' : 'N'),
           json.dig('rap_applied') ? (json.dig('rap_applied', 'uri') == json.dig('rap_attached', 'uri') ? 'N' : 'Y') : '',
           enum_for('runcorn_significance', result.dig('significance_u_sstr', 0)),
           boolean_for('significance_is_sticky', json, :invert),
           json['sensitivity_label'],
           json['agency_assigned_id'],
           json['previous_system_identifiers'],
           location_for(result, json),
           enum_for('runcorn_location', result.dig('current_location_u_sstr', 0)),
           enum_for('runcorn_physical_representation_availability', json['calculated_availability']),
           responsible_agency_for(result, json, 'qsa_id_prefixed'),
           responsible_agency_for(result, json, 'title'),
           boolean_for('responsible_agency_overrides_series_u_sbool', result),
          ].map {|e| e || ''}.to_csv
        }.join("")
      )
    end
  end

  def series_for(doc, json)
    case doc['primary_type']
    when /_representation$/
      [doc['controlling_record_series_qsa_id_u_ssort'], doc['controlling_record_series_title_u_ssort']].join(': ')
    when 'archival_object'
      [doc['series_summary_qsa_id_u_ssort'], doc['series_summary_title_u_ssort']].join(': ')
    when 'top_container'
      json['collection'].map{|c| [c['identifier'], c['display_string']].compact.join(': ')}.join('; ')
    end
  end

  def parent_for(doc, json)
    case doc['primary_type']
    when 'physical_representation'
      doc['controlling_record_qsa_id_u_ssort']
    when 'digital_representation'
      doc['controlling_record_qsa_id_u_ssort']
    when 'archival_object'
      Array(json['within']).find{|qsa_id| QSAId.parse_prefixed_id(qsa_id)[:model] == ArchivalObject} || series_for(doc, json)
    end
  end

  def format_for(doc, json)
    case doc['primary_type']
    when 'physical_representation'
      doc.dig('representation_format_u_sstr', 0)
    when 'digital_representation'
      json['file_type']
    when 'top_container'
      [doc.dig('container_profile_display_string_u_sstr', 0), enum_for('container_type', doc.dig('type_enum_s', 0))].compact.join('/ ')
    end
  end

  def container_for(doc, json)
    if doc['primary_type'] == 'physical_representation'
      doc.dig('top_container_title_u_sstr', 0)
    end
  end

  def location_for(doc, json)
    case doc['primary_type']
    when 'physical_representation'
      (json.dig('container', '_resolved', 'container_locations').find{|loc| loc['status'] == 'current'} || {}).dig('_resolved', 'title')
    when 'top_container'
      (json.dig('container_locations').find{|loc| loc['status'] == 'current'} || {}).dig('_resolved', 'title')
    end
  end

  def responsible_agency_for(doc, json, field)
    case doc['primary_type']
    when /_representation$/
      if field == 'qsa_id_prefixed'
        doc.dig('responsible_agency_qsa_id_u_sstr', 0)
      elsif field == 'title'
        doc.dig('responsible_agency_title_u_sstr', 0)
      end
    when 'archival_object'
      json.dig('responsible_agency', '_resolved', field)
    end
  end

  def boolean_for(fld, doc, invert = false)
    if doc.has_key?(fld)
      val = doc[fld]
      unless (bool = ASUtils.wrap(val).first).nil?
        bool = !bool if invert
        return bool ? 'Y' : 'N'
      end
    end
    ''
  end

  def date_for(doc, json, which, certainty = false)
    case doc['primary_type']
    when /_representation$/
      unless certainty
        json['controlling_record'][which.to_s + '_date']
      end
    when 'archival_object'
      date = json['dates'].select{|d| d['label'] == 'existence'}.first
      if date
        if certainty
          fld = 'certainty'
          fld += '_end' if which == :end
          date[fld]
        else
          date[which.to_s]
        end
      end
    end
  end

  def enum_for(enum, val)
    val ? I18n.t(['enumerations', enum, val].join('.')) : ''
  end

end
