class AgentsCSVExport < BaseCSVExport
  def columns
    [
      Column.new('Record Type', proc{|record| record.type}),
      Column.new('ID', proc{|record| record.id}),
      Column.new('Title', proc{|record| record.title}),
    ]
  end
end