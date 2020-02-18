class CsvExportFunctions < CsvExport

  def columns
    [
      Column.new('Record Type', proc{|record| record.type}),
      Column.new('Function ID', proc{|record| record.id}),
      Column.new('Function Name', proc{|record| record.title}),
      Column.new('Source', proc{|record| record.source}),
      Column.new('Start Date', proc{|record| record.start_date}),
      Column.new('Certainty', proc{|record| record.start_date_certainty}),
      Column.new('End Date', proc{|record| record.end_date}),
      Column.new('Certainty', proc{|record| record.end_date_certainty}),
      Column.new('No of Agencies Applied to', proc{|record| record.number_of_agency_relationships}),
      Column.new('No of Series Applied to', proc{|record| record.number_of_series_relationships}),
      Column.new('Published?', proc{|record| record.published}),
      Column.new('Created Date', proc{|record| record.created_date}),
      Column.new('Created By', proc{|record| record.created_by}),
      Column.new('Last Modified Date', proc{|record| record.last_modified_date}),
      Column.new('Last Modified By', proc{|record| record.last_modified_by}),
    ]
  end

  def process_results(solr_response, csv)
    @function_data = prep_extra_data(solr_response)
    super
  end

  def record_for_solr_doc(doc)
    record = super
    record.append_extra_data(@function_data.fetch(doc['id'], {}))
    record
  end

  def prep_extra_data(solr_response)
    function_data = {}
    function_refs = []

    Array(solr_response['results']).each do |doc|
      if doc['primary_type'] == 'function'
        function_refs << doc['id']
      end
    end

    # First let's look at Resources!
    query = Solr::Query.create_keyword_search('series_series_system_function_relationships_u_sstr:(%s)' % [function_refs.map{|uri| '"' + uri + '"'}.join(' OR ')])
    query.set_facets(['series_series_system_function_relationships_u_sstr'])
    query.set_record_types(['resource'])
    query.pagination(1, 1)
    query.set_repo_id(repo_id)
    query.add_solr_param(:"facet.limit", function_refs.length)
    query.use_standard_query_type
    results = Solr.search(query)

    (results.dig('facets', 'facet_fields', 'series_series_system_function_relationships_u_sstr') || []).each_slice(2).each do |uri, count|
      function_data[uri] ||= {}
      function_data[uri][:number_of_series_relationships] = count
    end

    function_data
  end
end