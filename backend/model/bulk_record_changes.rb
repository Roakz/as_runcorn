ColumnDef = Struct.new(:heading, :maps_to) do
  def initialize(heading, opts = {})
    self.heading = heading
    self.maps_to = opts.fetch(:maps_to, [])

    self
  end
end

COLUMNS = [
  COLUMN_SEQUENCE_NUMBER = ColumnDef.new('Sequence Number'),
  COLUMN_ATTACHED_TO_SEQUENCE_NUMBER = ColumnDef.new('Attachment Related to Sequence Number'),

  COLUMN_SERIES_ID = ColumnDef.new('Series ID'),
  COLUMN_ITEM_ID = ColumnDef.new('Item ID'),
  COLUMN_TITLE = ColumnDef.new('Title', :maps_to => ['title', 'physical_representations/:index/title']),
  COLUMN_START_DATE = ColumnDef.new('Start Date (DD/MM/YYYY)', :maps_to => ['dates']),
  COLUMN_CONTAINED_WITHIN = ColumnDef.new('Contained within',
                                          :maps_to => [
                                            'physical_representations/:index/contained_within',
                                            'digital_representations/:index/contained_within',
                                          ]),
  COLUMN_FORMAT = ColumnDef.new('Format',
                                :maps_to => [
                                  'physical_representations/:index/format',
                                  'digital_representations/:index/format',
                                ]),

  COLUMN_REPRESENTATION_TYPE = ColumnDef.new('Representation Type'),

]


class BulkRecordChanges

  Row = Struct.new(:values, :row_number) do
    def fetch(*args)
      args[0] = args[0].heading

      self.values.fetch(*args)
    end
  end

  Record = Struct.new(:row, :jsonmodel) do
    def self.parse(row, lookup)
      jsonmodel = parse_record(row, lookup)
      new(row, jsonmodel)
    end

    def self.parse_record(row, lookup)
      {
        :title => row.fetch(COLUMN_TITLE),
        :level => 'item',
        :resource => {'ref' => lookup.ref_for_qsa_id(row.fetch(COLUMN_SERIES_ID))},
        :physical_representations => [],
        :digital_representations => [],
      }
    end

    def add_representations(rows)
      @row_for_representation ||= {}

      rows.each do |row|
        if row.fetch(COLUMN_REPRESENTATION_TYPE) == 'PHYSICAL'
          @row_for_representation['physical_representations'] ||= []
          @row_for_representation['physical_representations'] << row.row_number

          self.jsonmodel[:physical_representations] <<  {
            :jsonmodel_type => 'physical_representation',
            :title => 'foo',
            :current_location => 'HOME',
            :normal_location => 'HOME',
          }
        else
          @row_for_representation['digital_representations'] ||= []
          @row_for_representation['digital_representations'] << row.row_number

          self.jsonmodel[:digital_representations] << {
            :jsonmodel_type => 'digital_representation',
            :title => 'foo',
            :current_location => 'HOME',
            :normal_location => 'HOME',
          }
        end
      end
    end

    def failed_row_for_field(error_field)
      if error_field =~ %r{\A(physical_representations|digital_representations)/([0-9]+)/}
        representation_type = $1
        representation_index = Integer($2)

        # FIXME: Might blow up?
        return @row_for_representation.fetch(representation_type, []).fetch(representation_index)
      end

      self.row.row_number
    end
  end

  class Lookup
    def initialize(resources)
      @qsa_ids = lookup_qsa_ids(Resource, resources.fetch(:resource_qsa_ids, []))
    end

    def ref_for_qsa_id(qsa_id)
      @qsa_ids.fetch(qsa_id)
    end

    private

    def lookup_qsa_ids(model, prefixed_qsa_ids)
      qsa_ids = prefixed_qsa_ids
                  .map {|prefixed_qsa_id| QSAId.parse_prefixed_id(prefixed_qsa_id)}
                  .select {|parsed| parsed[:model] == model && parsed[:id]}
                  .map {|parsed| parsed[:id]}

      model.filter(:qsa_id => qsa_ids).select(:id, :qsa_id).map {|row|
        [QSAId.prefixed_id_for(model, row[:qsa_id]),
         model.uri_for(model.my_jsonmodel.record_type,
                       row[:id],
                       :repo_id => RequestContext.get(:repo_id))]
      }.to_h
    end
  end


  def self.run(filename)
    rows_by_series = {}
    rows_by_sequence_number = {}
    rows_by_attached_to_sequence_number = {}

    each_row(filename) do |row|
      if (attached_to_sequence_number = row.fetch(COLUMN_ATTACHED_TO_SEQUENCE_NUMBER, nil))
        rows_by_attached_to_sequence_number[attached_to_sequence_number] ||= []
        rows_by_attached_to_sequence_number[attached_to_sequence_number] << row
      else
        if (series_qsa_id = row.fetch(COLUMN_SERIES_ID, nil))
          rows_by_series[series_qsa_id] ||= []
          rows_by_series[series_qsa_id] << row
        end

        if (sequence_number = row.fetch(COLUMN_SEQUENCE_NUMBER, nil))
          rows_by_sequence_number[sequence_number] = row
        end
      end
    end

    lookup = Lookup.new(:resource_qsa_ids => rows_by_series.keys)

    records_to_create = []
    records_to_update = []

    rows_by_series.values.flatten(1).each do |row|
      record = Record.parse(row, lookup)

      if row.fetch(COLUMN_SEQUENCE_NUMBER, nil)
        # Look for representations too
        representation_rows = rows_by_attached_to_sequence_number.fetch(row.fetch(COLUMN_SEQUENCE_NUMBER))

        record.add_representations(representation_rows)
      end

      if row.fetch(COLUMN_ITEM_ID, nil)
        records_to_update << record
      else
        records_to_create << record
      end
    end

    errors = []

    records_to_create.each do |record|
      jsonmodel = JSONModel::JSONModel(:archival_object).new(record.jsonmodel)
      validate_result = jsonmodel._exceptions

      unless validate_result.empty?
        errors << {:errors => validate_result, :record => record}
        next
      end

      begin
        ArchivalObject.create_from_json(jsonmodel)
      rescue
        # Sequel errors, constraints?
        raise $!
      end
    end

    records_for_update = load_records_for_update(records_to_update.map {|record| record.row.fetch(COLUMN_ITEM_ID)})

    records_to_update.each do |record|
      jsonmodel = JSONModel::JSONModel(:archival_object).new(record.jsonmodel)
      validate_result = jsonmodel._exceptions

      unless validate_result.empty?
        errors << {:errors => validate_result, :record => record}
        next
      end

      begin
        ArchivalObject.create_from_json(jsonmodel)
      rescue
        # Sequel errors, constraints?
        raise $!
      end
    end

    unless errors.empty?
      # Important to raise an exception so we rollback the outer transaction.
      raise BulkUpdateFailed.new(errors)
    end
  end

  def self.load_records_for_update(ao_qsa_ids)
    qsa_ids = ao_qsa_ids.map {|prefixed_qsa_id| QSAId.parse_prefixed_id(prefixed_qsa_id){:id]}
                .map {|parsed| parsed[:id]}

    model.filter(:qsa_id => qsa_ids).select(:id, :qsa_id).map {|row|
      [QSAId.prefixed_id_for(model, row[:qsa_id]),
       model.uri_for(model.my_jsonmodel.record_type,
                     row[:id],
                     :repo_id => RequestContext.get(:repo_id))]
    }.to_h
  end

  def self.model_for(jsonmodel_type)
    Kernel.const_get(jsonmodel_type.to_s.camelize)
  end


  def self.parse_record(record)
    title = record.values.fetch(COLUMN_TITLE)
  end

  def self.each_row(filename)
    headers = nil

    XLSXStreamingReader.new(filename).each.each_with_index do |row, idx|
      if idx == 0
        headers = row_values(row)
      else
        yield Row.new(headers.zip(row_values(row)).to_h, idx)
      end
    end
  end

  def self.row_values(row)
    row.map {|s|
      result = s.to_s.strip
      result.empty? ? nil : result
    }
  end

  class BulkUpdateFailed < StandardError
    def initialize(errors)
      @errors = errors
    end

    def to_json
      result = {}

      @errors.each do |error|
        error[:errors].fetch(:errors, []).each do |(json_field, error_messages)|
          failed_row = error[:record].failed_row_for_field(json_field)

          error_column = COLUMNS.find {|column| column.maps_to.include?(generify_property(json_field))}
          result[failed_row] ||= {}

          if error_column
            result[failed_row][error_column.heading] = error_messages
          else
            result[failed_row]['UNMAPPED_ERROR_' + json_field] = error_messages
          end
        end
      end

      result.sort_by {|k, _| k}.to_h
    end

    private

    def generify_property(s)
      s.gsub(%r{/[0-9]+/}, '/:index/')
    end
  end

end
