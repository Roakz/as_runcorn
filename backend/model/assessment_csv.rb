require 'csv'

class AssessmentCSV

  HEADERS = [
    'Representation ID',
    'Representation Title',
    'Representation Format',
    'Responsible Agency ID',
    'Responsible Agency Title',
    'Controlling Record Date - Start',
    'Controlling Record Date - End',
    'Frequency of Use',
    'Significance',
    'Container Title',
    'Container Location',
    'Container Location - Description',
    '# Awaiting Treatment',
    '# Treatments In Progress',
    '# Treatments Completed',
  ]

  def self.for_refs(assessment_id, many_many_refs)
    new(assessment_id, many_many_refs)
  end

  def initialize(assessment_id, refs)
    @assessment_id = assessment_id
    @refs = refs
  end

  def search_by_refs(refs)
    query = "{!terms f=id}" + refs.join(',')

    results = Search.search({
                              :q => query,
                              :page => 1,
                              :page_size => AppConfig[:max_page_size],
                            }, RequestContext.get(:repo_id))
  end

  def each_chunk(&block)
    block.call(HEADERS.to_csv)

    @refs.each_slice(AppConfig[:max_page_size]) do |slice|
      results = search_by_refs(slice)

      Assessment.add_treatment_summaries_to_search_results(@assessment_id, results)

      block.call(
        results['results'].map {|result|
          treatments_summary = ASUtils.json_parse(result.fetch('treatments_summary'))
          [
            result['qsa_id_u_ssort'],
            result['title'],
            result.dig('representation_format_u_sstr', 0),
            result.dig('responsible_agency_qsa_id_u_sstr', 0),
            result.dig('responsible_agency_title_u_sstr', 0),
            result['controlling_record_begin_date_u_ssort'],
            result['controlling_record_end_date_u_ssort'],
            result.dig('frequency_of_use_u_sint', 0),
            result.dig('significance_u_sstr', 0),
            result.dig('top_container_title_u_sstr', 0),
            result.dig('top_container_location_u_sstr', 0),
            result.dig('top_container_home_location_u_sstr', 0),
            treatments_summary.fetch('awaiting_treatment', 0),
            treatments_summary.fetch('in_progress', 0),
            treatments_summary.fetch('completed', 0),
          ].map {|e| e || ''}.to_csv
        }.join("")
      )
    end
  end

end
