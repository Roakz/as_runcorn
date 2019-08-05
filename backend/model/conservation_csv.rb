require 'csv'

class ConservationCSV

  HEADERS = [
    'Representation ID',
    'Representation Title',
    'Responsible Agency ID',
    'Responsible Agency Title',
    'Controlling Record Date - Start',
    'Controlling Record Date - End',
    'Frequency of Use',
    'Significance',
    'Container Title',
    'Container Location',
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
          [
            result['qsa_id_u_ssort'],
            result['title'],
            result.dig('responsible_agency_qsa_id_u_sstr', 0),
            result.dig('responsible_agency_title_u_sstr', 0),
            result['controlling_record_begin_date_u_ssort'],
            result['controlling_record_end_date_u_ssort'],
            result.dig('frequency_of_use_u_sint', 0),
            result.dig('significance_u_sstr', 0),
            result.dig('top_container_title_u_sstr', 0),
            result.dig('top_container_location_u_sstr', 0),
          ].map {|e| e || ''}.to_csv
        }.join("")
      )
    end
  end



end
