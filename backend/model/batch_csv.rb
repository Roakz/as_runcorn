require 'csv'

class BatchCSV

  HEADERS = [
    'Record Type',
    'ID',
    'Title',
    'Parent series',
    'Approved?',
    'Published?',
    'Significance level',
    'RAP public details?',
    'RAP Access Category',
    'RAP Years',
    'RAP Notice date',
    'RAP Internal reference',
    'Current (functional) location',
    'Subject',
    'Sensitivity label',
  ]

  def self.for_refs(many_many_refs)
    new(many_many_refs)
  end

  def series_for(doc, json)
    case doc['primary_type']
    when 'physical_representation'
      doc['controlling_record_series_qsa_id_u_ssort']
    when 'digital_representation'
      Array(json['within']).find{|qsa_id| QSAId.parse_prefixed_id(qsa_id)[:model] == Resource}
    when 'archival_object'
      Array(json['within']).find{|qsa_id| QSAId.parse_prefixed_id(qsa_id)[:model] == Resource}
    end
  end

  def boolean_for(fld, doc)
    if doc.has_key?(fld)
      val = doc[fld]
      unless (bool = ASUtils.wrap(val).first).nil?
        return bool ? 'Y' : 'N'
      end
    end
    ''
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
            result['title'],
            series_for(result, json),
            boolean_for('archivist_approved_u_sbool', result),
            boolean_for('publish', result),
            result.dig('significance_u_sstr', 0) ? I18n.t('enumerations.runcorn_significance.' + result.dig('significance_u_sstr', 0)) : '',
            json.dig('rap_applied', 'open_access_metadata') ? (json.dig('rap_applied', 'open_access_metadata') == 'true' ? 'Y' : 'N') : '',
            json.dig('rap_applied', 'access_category'),
            json.dig('rap_applied', 'years'),
            json.dig('rap_applied', 'notice_date'),
            json.dig('rap_applied', 'internal_reference'),
            result.dig('current_location_u_sstr', 0) ? I18n.t('enumerations.runcorn_location.' + result.dig('current_location_u_sstr', 0)) : '',
            result.fetch('subjects', []).join('; '),
            json['sensitivity_label'],
          ].map {|e| e || ''}.to_csv
        }.join("")
      )
    end
  end
end
