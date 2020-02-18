require_relative 'csv_export'

class CsvExportAgents < CsvExport

  def columns
    [
      Column.new('Record Type', proc{|record| record.type}),
      Column.new('ID', proc{|record| record.id}),
      Column.new('Agent Name', proc{|record| record.agent_name}),
      Column.new('Non Preferred Name', proc{|record| record.agent_non_preferred_names}),
      Column.new('Acronym', proc{|record| record.agency_acronym}),
      Column.new('Start Date', proc{|record| record.start_date}),
      Column.new('Certainty', proc{|record| record.start_date_certainty}),
      Column.new('End Date', proc{|record| record.end_date}),
      Column.new('Certainty', proc{|record| record.end_date_certainty}),
      Column.new('Agency Category', proc{|record| record.agency_category}),
      Column.new('Status', proc{|record| record.agent_status}),
      Column.new('No. of Series Controlled', proc{|record| record.number_of_series_controlled}),
      Column.new('No of Items in other Series Controlled', proc{|record| record.number_of_items_in_other_series_controlled}),
      Column.new('Creating Agency?', proc{|record| record.agency_creating_agency}),
      Column.new('Status', proc{|record| record.agency_status}),
      Column.new('Published?', proc{|record| record.published}),
      Column.new('Created Date', proc{|record| record.created_date}),
      Column.new('Created By', proc{|record| record.created_by}),
      Column.new('Last Modified Date', proc{|record| record.last_modified_date}),
      Column.new('Last Modified By', proc{|record| record.last_modified_by}),
    ]
  end

  def process_results(solr_response, csv)
    @agent_data = prep_extra_agent_data(solr_response)
    super
  end

  def record_for_solr_doc(doc)
    record = super
    record.append_extra_data(@agent_data.fetch(doc['id'], {}))
    record
  end

  def prep_extra_agent_data(solr_response)
    agent_data = {}
    agency_refs = []

    Array(solr_response['results']).each do |doc|
      if doc['primary_type'] == 'agent_corporate_entity'
        agency_refs << doc['id']
      end
    end

    # First let's look at Resources!
    query = Solr::Query.create_keyword_search('responsible_agency_u_sstr:(%s)' % [agency_refs.map{|uri| '"' + uri + '"'}.join(' OR ')])
    query.set_facets(['responsible_agency_u_sstr', 'creating_agency_u_sstr'])
    query.set_record_types(['resource'])
    query.pagination(1, 1)
    query.set_repo_id(repo_id)
    query.add_solr_param(:"facet.limit", agency_refs.length)
    query.use_standard_query_type
    results = Solr.search(query)

    (results.dig('facets', 'facet_fields', 'responsible_agency_u_sstr') || []).each_slice(2).each do |uri, count|
      agent_data[uri] ||= {}
      agent_data[uri][:number_of_series_controlled] = count
    end

    (results.dig('facets', 'facet_fields', 'creating_agency_u_sstr') || []).each_slice(2).each do |uri, count|
      agent_data[uri] ||= {}
      agent_data[uri][:is_agency_creating_agency] = count > 0
    end

    # Now do the Archival Objects!
    query = Solr::Query.create_keyword_search('responsible_agency_u_sstr:(%s)' % [agency_refs.map{|uri| '"' + uri + '"'}.join(' OR ')])
    query.set_facets(['creating_agency_u_sstr', 'responsible_agency_overrides_series_u_sstr'])
    query.set_record_types(['archival_object'])
    query.pagination(1, 1)
    query.set_repo_id(repo_id)
    query.add_solr_param(:"facet.limit", agency_refs.length)
    query.use_standard_query_type
    results = Solr.search(query)

    (results.dig('facets', 'facet_fields', 'creating_agency_u_sstr') || []).each_slice(2).each do |uri, count|
      agent_data[uri] ||= {}
      unless agent_data[uri][:is_agency_creating_agency]
        agent_data[uri][:is_agency_creating_agency] = count > 0
      end
    end

    (results.dig('facets', 'facet_fields', 'responsible_agency_overrides_series_u_sstr') || []).each_slice(2).each do |uri, count|
      agent_data[uri] ||= {}
      agent_data[uri][:number_of_items_in_other_series_controlled] = count
    end

    agent_data
  end
end