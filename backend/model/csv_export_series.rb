class CsvExportSeries < CsvExport

  def columns
    [
      Column.new('Record Type', proc{|record| record.type}),
      Column.new('Series ID', proc{|record| record.id}),
      Column.new('Series Name', proc{|record| record.title}),
      Column.new('Start Date', proc{|record| record.start_date}),
      Column.new('Certainty', proc{|record| record.start_date_certainty}),
      Column.new('End Date', proc{|record| record.end_date}),
      Column.new('Certainty', proc{|record| record.end_date_certainty}),
      Column.new('No of Items', proc{|record| record.number_of_children}),
      Column.new('No of Physical Representations', proc{|record| record.number_of_physical_representations}),
      Column.new('No of Digital Representations', proc{|record| record.number_of_digital_representations}),
      Column.new('No of Transfers into Series', proc{|record| record.number_of_transfers_into_series}),
      Column.new('No of Top Containers', proc{|record| record.number_of_top_containers}),
      Column.new('RAP Duration', proc{|record| record.rap_years}),
      Column.new('Access Category', proc{|record| record.access_category}),
      Column.new('RAP Publish Details?', proc{|record| record.rap_publish_details}),
      Column.new('Contains Items/ Reps with overriding RAPs?', proc{|record| record.has_overriding_raps}),
      Column.new('Responsible Agency ID', proc{|record| record.responsible_agency_id}),
      Column.new('Responsible Agency Name', proc{|record| record.responsible_agency_name}),
      Column.new('No of other Responsible Agencies', proc{|record| record.number_of_other_responsible_agencies}),
      Column.new('No of Items with Overriding Responsible Agencies', proc{|record| record.number_of_items_with_overidden_responsible_agency}),
      Column.new('No of Significant Items (Memory of the World)', proc{|record| record.number_of_significant_items_mow}),
      Column.new('No of Significant Items (Iconic)', proc{|record| record.number_of_significant_items_iconic}),
      Column.new('No of Significant Items (High)', proc{|record| record.number_of_significant_items_high}),
      Column.new('Sensitivity Label', proc{|record| record.sensitivity_label}),
      Column.new('Archivist Approved?', proc{|record| record.archivist_approved}),
      Column.new('Approval Date', proc{|record| record.archivist_approval_date}),
      Column.new('Approved By', proc{|record| record.archivist_approved_by}),
      Column.new('Published?', proc{|record| record.published}),
      Column.new('Restrictions Apply?', proc{|record| record.restrictions_apply}),
      Column.new('Serialised?', proc{|record| record.serialised}),
      Column.new('Previous System Location', proc{|record| record.previous_system_identifier}),
      Column.new('Retention Status', proc{|record| record.accessioned_retention_status}),
      Column.new('Disposal Class', proc{|record| record.disposal_class}),
      Column.new('Copyright Status', proc{|record| record.copyright_status}),
      Column.new('Created Date', proc{|record| record.created_date}),
      Column.new('Created By', proc{|record| record.created_by}),
      Column.new('Last Modified Date', proc{|record| record.last_modified_date}),
      Column.new('Last Modified By', proc{|record| record.last_modified_by}),
    ]
  end

  def process_results(solr_response, csv)
    @series_data = prep_extra_series_data(solr_response)
    super
  end

  def record_for_solr_doc(doc)
    record = super
    record.append_extra_data(@series_data.fetch(doc['id'], {}))
    record
  end

  def prep_extra_series_data(solr_response)
    series_data = {}
    series_refs = []

    Array(solr_response['results']).each do |doc|
      if doc['primary_type'] == 'resource'
        series_refs << doc['id']
      end
    end

    query = Solr::Query.create_keyword_search('controlling_record_series_u_sstr:(%s)' % [series_refs.map{|uri| '"' + uri + '"'}.join(' OR ')])
    query.set_facets(['series_top_container_uri_u_sstr'])
    query.set_record_types(['physical_representation'])
    query.pagination(1, 1)
    query.set_repo_id(repo_id)
    query.add_solr_param(:"facet.limit", series_refs.length)
    query.use_standard_query_type
    results = Solr.search(query)

    (results.dig('facets', 'facet_fields', 'series_top_container_uri_u_sstr') || []).each_slice(2).each do |facet_value, _|
      resource_uri, _ = facet_value.split('::')
      series_data[resource_uri] ||= {}
      series_data[resource_uri][:number_of_top_containers] ||= 0
      series_data[resource_uri][:number_of_top_containers] += 1
    end

    # No of Items with Overriding Responsible Agencies
    query = Solr::Query.create_keyword_search('series_with_responsible_agency_overrides_u_sstr:(%s)' % [series_refs.map{|uri| '"' + uri + '"'}.join(' OR ')])
    query.set_facets(['series_with_responsible_agency_overrides_u_sstr'])
    query.set_record_types(['archival_object'])
    query.pagination(1, 1)
    query.set_repo_id(repo_id)
    query.add_solr_param(:"facet.limit", series_refs.length)
    query.use_standard_query_type
    results = Solr.search(query)

    (results.dig('facets', 'facet_fields', 'series_with_responsible_agency_overrides_u_sstr') || []).each_slice(2).each do |uri, count|
      series_data[uri] ||= {}
      series_data[uri][:number_of_items_with_overidden_responsible_agency] = count
    end

    series_data
  end

end