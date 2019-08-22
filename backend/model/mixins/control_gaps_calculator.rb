module ControlGapsCalculator

  class GapAnalysis
    attr_reader :gaps

    def initialize
      @gaps = []
    end

    def reference(model, id)
      [model, id]
    end

    def load_tree(db, resource_id)
      record_to_parent = {}

      db[:archival_object]
        .filter(:root_record_id => resource_id)
        .select(:id, :parent_id)
        .each do |row|
        if row[:parent_id]
          record_to_parent[reference(ArchivalObject, row[:id])] = reference(ArchivalObject, row[:parent_id])
        else
          record_to_parent[reference(ArchivalObject, row[:id])] = reference(Resource, resource_id)
        end
      end

      record_to_parent
    end

    def load_connected_date(db, resource_id)
      dates_for_records = {}

      db[:date]
        .filter(:resource_id => resource_id)
        .filter(Sequel.~(:begin => nil))
        .select(:resource_id, :begin)
        .each do |row|
        dates_for_records[reference(Resource, row[:resource_id])] ||= DateParse.date_parse_down(row[:begin])
      end

      db[:date]
        .filter(:archival_object_id => db[:archival_object].filter(:root_record_id => resource_id).select(:id))
        .filter(Sequel.~(:begin => nil))
        .select(:archival_object_id, :begin)
        .each do |row|
        dates_for_records[reference(ArchivalObject, row[:archival_object_id])] ||= row[:begin]
      end

      dates_for_records
    end

    def load_connected_controlling_agency_dates(db, resource_id)
      control_data_by_record = {}

      db[:series_system_rlshp]
        .filter(:resource_id_0 => resource_id)
        .filter(:jsonmodel_type => 'series_system_agent_record_ownership_relationship')
        .select(:resource_id_0, :start_date, :end_date)
        .each do |row|
        control_data_by_record[reference(Resource, row[:resource_id_0])] ||= []
        control_data_by_record[reference(Resource, row[:resource_id_0])] << [row[:start_date], row[:end_date]]
      end

      db[:series_system_rlshp]
        .filter(:archival_object_id_0 => db[:archival_object].filter(:root_record_id => resource_id).select(:id))
        .filter(:jsonmodel_type => 'series_system_agent_record_ownership_relationship')
        .select(:archival_object_id_0, :start_date, :end_date)
        .each do |row|
        control_data_by_record[reference(ArchivalObject, row[:archival_object_id_0])] ||= []
        control_data_by_record[reference(ArchivalObject, row[:archival_object_id_0])] << [row[:start_date], row[:end_date]]
      end

      control_data_by_record
    end

    def call(resource_obj)
      # Ensure we process the broadest existence range for the resource
      # as determined the all_existence_dates mixin
      date_calculator = DateCalculator.new(resource_obj, 'existence', true, :allow_open_end => true)
      resource_obj.date.first.begin = date_calculator.min_begin

      DB.open do |db|
        record_to_parent = load_tree(db, resource_obj.id)
        connected_date = load_connected_date(db, resource_obj.id)
        connected_controlling_agency_dates = load_connected_controlling_agency_dates(db, resource_obj.id)

        record_to_parent.each do |record_reference, parent_reference|
          next unless connected_date.has_key?(record_reference)

          record_start_date = DateParse.date_parse_down(connected_date.fetch(record_reference))

          all_controlling_dates = connected_controlling_agency_dates.fetch(record_reference, [])
          next_to_process = parent_reference
          while(!next_to_process.nil?) do
            all_controlling_dates += connected_controlling_agency_dates.fetch(parent_reference, [])
            next_to_process = record_to_parent[parent_reference]
          end

          total_lifespan = DateRange.new(record_start_date, nil)
          gaps = [total_lifespan]

          all_controlling_dates.each do |start_date, end_date|
            parsed_start = DateParse.date_parse_down(start_date)
            parsed_end = end_date ? DateParse.date_parse_up(end_date) : nil
            date_range = DateRange.new(parsed_start, parsed_end)

            next_lifespan = []
            gaps.each do |lifespan_date_range|
              bits = lifespan_date_range.remove_range(date_range)
              next_lifespan.concat(bits)
            end
            gaps = next_lifespan
          end

          unless gaps.empty?
            @gaps << {
              :ref => uri_for(record_reference),
              :gaps => gaps,
              :qsa_id => 'FIXME',
              :display_string => 'FIXME',
            }
          end
        end
      end
    end

    def uri_for(reference)
      if reference[0] == ArchivalObject
        JSONModel(:archival_object).uri_for(reference[1])
      else
        JSONModel(:resource).uri_for(reference[1])
      end
    end
  end

  def calculate_gaps_in_control!
    gap_analyzer = GapAnalysis.new
    gap_analyzer.call(self)
    gap_analyzer.gaps.map {|gap_description|
      gap_description.merge(:gaps => gap_description[:gaps].map {|gap|
        {
          'start_date' => gap.start_date.strftime('%Y-%m-%d'),
          'end_date' => gap.end_date.strftime('%Y-%m-%d'),
        }
      })
    }
  end
end
