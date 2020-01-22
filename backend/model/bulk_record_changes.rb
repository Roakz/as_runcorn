ColumnDef = Struct.new(:heading, :record_types, :required) do
  def initialize(heading:, record_types:, required: false)
    self.heading = heading
    self.record_types = record_types,
    self.required = required

    self
  end
end

COLUMNS = [
  ColumnDef.new(heading: 'Series ID', record_types: [:archival_object, :physical_representation, :digital_representation], required: true),
  ColumnDef.new(heading: 'Item ID', record_types: []),
  ColumnDef.new(heading: 'Parent Item ID', record_types: []),
  ColumnDef.new(heading: 'Responsible Agency ID', record_types: []),
  ColumnDef.new(heading: 'Responsible Agency Start Date (DD/MM/YYYY)', record_types: []),
  ColumnDef.new(heading: 'Responsible Agency End Date (DD/MM/YYYY)', record_types: []),
  ColumnDef.new(heading: 'Creating Agency ID', record_types: []),
  ColumnDef.new(heading: 'Creating Agency Start Date (DD/MM/YYYY)', record_types: []),
  ColumnDef.new(heading: 'Creating Agency End Date (DD/MM/YYYY)', record_types: []),
  ColumnDef.new(heading: 'Title', record_types: []),
  ColumnDef.new(heading: 'Description', record_types: []),
  ColumnDef.new(heading: 'Sequence Number', record_types: []),
  ColumnDef.new(heading: 'Attachment Related to Sequence Number', record_types: []),
  ColumnDef.new(heading: 'Attachment Notes', record_types: []),
  ColumnDef.new(heading: 'Agency Control number', record_types: []),
  ColumnDef.new(heading: 'Box Number', record_types: []),
  ColumnDef.new(heading: 'Publish Metadata?', record_types: []),
  ColumnDef.new(heading: 'Start Date (DD/MM/YYYY)', record_types: []),
  ColumnDef.new(heading: 'Start Date Qual', record_types: []),
  ColumnDef.new(heading: 'End Date (DD/MM/YYYY)', record_types: []),
  ColumnDef.new(heading: 'End Date Qual', record_types: []),
  ColumnDef.new(heading: 'Restricted Access Period', record_types: []),
  ColumnDef.new(heading: 'Representation Type', record_types: []),
  ColumnDef.new(heading: 'Format', record_types: []),
  ColumnDef.new(heading: 'Contained within', record_types: []),
  ColumnDef.new(heading: 'Sensitivity Label', record_types: []),
  ColumnDef.new(heading: 'Remark', record_types: []),
  ColumnDef.new(heading: 'Transfer ID', record_types: []),
  ColumnDef.new(heading: 'Previous System ID', record_types: []),
  ColumnDef.new(heading: 'Significance', record_types: []),
  ColumnDef.new(heading: 'Copyright status', record_types: []),
  ColumnDef.new(heading: 'Subjects (Separate with ;)', record_types: []),
]


class BulkRecordChanges
end
