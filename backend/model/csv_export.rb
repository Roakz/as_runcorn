class CsvExport
  attr_accessor :criteria, :repo_id

  def initialize(criteria, repo_id)
    @criteria = criteria
    @repo_id = repo_id
  end

  Column = Struct.new(:heading, :value)

  def columns
    [
      Column.new('Record Type', proc{|record| record.type}),
      Column.new('ID', proc{|record| record.id}),
      Column.new('Title', proc{|record| record.title}),
      Column.new('Start Date', proc{|record| record.start_date}),
      Column.new('Certainty', proc{|record| record.start_date_certainty}),
      Column.new('End Date', proc{|record| record.end_date}),
      Column.new('Certainty', proc{|record| record.end_date_certainty}),
      Column.new('Found In', proc{|record| record.found_in}),
      Column.new('Published?', proc{|record| record.published}),
      Column.new('Archivist Approved?', proc{|record| record.archivist_approved}),
      Column.new('Accessioned/ Retention Status', proc{|record| record.accessioned_retention_status}),
      Column.new('Category/ Format', proc{|record| record.category_format}),
      Column.new('Associated Record ID', proc{|record| record.associated_record_id}),
      Column.new('Contained Within', proc{|record| record.contained_within}),
      Column.new('Top Container', proc{|record| record.top_container}),
      Column.new('RAP Years', proc{|record| record.rap_years}),
      Column.new('RAP Status', proc{|record| record.rap_status}),
      Column.new('RAP Expiry Date', proc{|record| record.rap_expiry_date}),
      Column.new('Access Category', proc{|record| record.access_category}),
      Column.new('RAP Publish Details?', proc{|record| record.rap_publish_details}),
      Column.new('RAP is inherited?', proc{|record| record.rap_is_inherited}),
      Column.new('Significance', proc{|record| record.significance}),
      Column.new('Inherit Significance?', proc{|record| record.inherit_significance}),
      Column.new('Sensitivity Label', proc{|record| record.sensitivity_label}),
      Column.new('Agency Control No.', proc{|record| record.agency_control_number}),
      Column.new('Previous System Location', proc{|record| record.previous_system_identifier}),
      Column.new('Disposal Class', proc{|record| record.disposal_class}),
      Column.new('Home Location', proc{|record| record.home_location}),
      Column.new('Current Location', proc{|record| record.current_location}),
      Column.new('Availability', proc{|record| record.availability}),
      Column.new('Status', proc{|record| record.status}),
      Column.new('Colour', proc{|record| record.colour}),
      Column.new('File Size', proc{|record| record.file_size}),
      Column.new('File Issue Allowed?', proc{|record| record.file_issue_allowed}),
      Column.new('Exhibition Quality?', proc{|record| record.exhibition_quality}),
      Column.new('Intended Use', proc{|record| record.intended_use}),
      Column.new('Original Registration Date', proc{|record| record.original_registration_date}),
      Column.new('Serialised?', proc{|record| record.serialised}),
      Column.new('Accrual?', proc{|record| record.accrual}),
      Column.new('Reason Requested', proc{|record| record.reason_requested}),
      Column.new('Source', proc{|record| record.source}),
      Column.new('Responsible Agency ID', proc{|record| record.responsible_agency_id}),
      Column.new('Responsible Agency Name', proc{|record| record.responsible_agency_name}),
      Column.new('Responsible Agency Inherited?', proc{|record| record.responsible_agency_inherited}),
      Column.new('Repository', proc{|record| record.repository}),
      Column.new('Floor', proc{|record| record.floor}),
      Column.new('Room', proc{|record| record.room}),
      Column.new('Area', proc{|record| record.area}),
      Column.new('Location Profile', proc{|record| record.location_profile}),
      Column.new('Treatment Status', proc{|record| record.treatment_status}),
      Column.new('Treatments Applied', proc{|record| record.treatments_applied}),
      Column.new('Date Commenced ', proc{|record| record.date_commenced}),
      Column.new('Date Completed', proc{|record| record.date_completed}),
      Column.new('Assessment ID', proc{|record| record.assessment_id}),
      Column.new('Created Date', proc{|record| record.created_date}),
      Column.new('Created By', proc{|record| record.created_by}),
      Column.new('Last Modified Date', proc{|record| record.last_modified_date}),
      Column.new('Last Modified By', proc{|record| record.last_modified_by}),
    ]
  end

  def to_csv
    tempfile = Tempfile.new('SearchExport')

    CSV.open(tempfile, 'w') do |csv|
      csv << columns.map(&:heading)

      while(true) do
        result = Search.search(criteria, repo_id)

        break if Array(result['results']).empty?

        process_results(result, csv)

        break if result['last_page'] <= result['this_page']

        criteria[:page] = criteria[:page] + 1
      end
    end

    tempfile.rewind
    tempfile
  end

  def process_results(solr_response, csv)
    solr_response['results'].each do |doc|
      record = record_for_solr_doc(doc)
      csv << columns.map {|col| col.value.call(record)}
    end
  end

  def record_for_solr_doc(doc)
    json = ASUtils.json_parse(doc['json'])
    CSVExportRecord.new(doc, json)
  end
end