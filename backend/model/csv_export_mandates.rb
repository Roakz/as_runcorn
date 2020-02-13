class CsvExportMandates < CsvExport

  def columns
    [
      Column.new('Record Type', proc{|record| record.type}),
      Column.new('Mandate ID', proc{|record| record.id}),
      Column.new('Mandate Name', proc{|record| record.title}),
      Column.new('type', proc{|record| record.category_format}),
      Column.new('Start Date', proc{|record| record.start_date}),
      Column.new('Certainty', proc{|record| record.start_date_certainty}),
      Column.new('End Date', proc{|record| record.end_date}),
      Column.new('Certainty', proc{|record| record.end_date_certainty}),
      Column.new('No of Agency Relationships', proc{|record| record.number_of_agency_relationships}),
      Column.new('No of Mandate Relationships', proc{|record| record.number_of_mandate_relationships}),
      Column.new('No of Function Relationships', proc{|record| record.number_of_function_relationships}),
      Column.new('Published?', proc{|record| record.published}),
      Column.new('Created Date', proc{|record| record.created_date}),
      Column.new('Created By', proc{|record| record.created_by}),
      Column.new('Last Modified Date', proc{|record| record.last_modified_date}),
      Column.new('Last Modified By', proc{|record| record.last_modified_by}),
    ]
  end

end