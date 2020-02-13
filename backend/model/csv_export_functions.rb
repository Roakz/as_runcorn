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

end