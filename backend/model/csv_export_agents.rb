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
    super
  end

  def prep_extra_agent_data(solr_response)
    agency_refs = []

    Array(solr_response['results']).each do |doc|
      if doc['primary_type'] == 'agent_corporate_entity'
        agency_refs << doc['id']
      end
    end

    # FIXME this crap
  end
end