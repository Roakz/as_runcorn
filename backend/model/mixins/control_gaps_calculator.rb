module ControlGapsCalculator

  class GapAnalysis
    attr_reader :gaps

    def initialize
      @gaps = {}
    end

    def reference(model, id)
      [model, id]
    end

    def load_tree(db, resource_obj)
      record_to_parent = {
        reference(Resource, resource_obj.id) => nil,
      }

      db[:archival_object]
        .filter(:root_record_id => resource_obj.id)
        .select(:id, :parent_id)
        .each do |row|
        if row[:parent_id]
          record_to_parent[reference(ArchivalObject, row[:id])] = reference(ArchivalObject, row[:parent_id])
        else
          record_to_parent[reference(ArchivalObject, row[:id])] = reference(Resource, resource_obj.id)
        end
      end

      record_to_parent
    end

    def load_connected_date(db, resource_obj)
      date_calculator = DateCalculator.new(resource_obj, 'existence', true, :allow_open_end => true)
      dates_for_records = {
        reference(Resource, resource_obj.id) => date_calculator.min_begin
      }

      db[:date]
        .filter(:archival_object_id => db[:archival_object].filter(:root_record_id => resource_obj.id).select(:id))
        .filter(Sequel.~(:begin => nil))
        .select(:archival_object_id, :begin)
        .each do |row|
        dates_for_records[reference(ArchivalObject, row[:archival_object_id])] ||= row[:begin]
      end

      dates_for_records
    end

    def load_metadata(references)
      metadata = {}

      references.group_by{|ref| ref[0]}.each do |record_model, record_references|
        if record_model == Resource
          Resource
            .filter(:id => record_references.map{|ref| ref[1]})
            .select(:id, :qsa_id, :title)
            .each do |row|
            metadata[reference(Resource, row[:id])] = {
              :qsa_id => QSAId.prefixed_id_for(Resource, row[:id]),
              :display_string => row[:title],
            }
          end
        else
          record_model
            .filter(:id => record_references.map{|ref| ref[1]})
            .select(:id, :qsa_id, :display_string)
            .each do |row|
            metadata[reference(record_model, row[:id])] = {
              :qsa_id => QSAId.prefixed_id_for(record_model, row[:id]),
              :display_string => row[:display_string],
            }
          end
        end
      end

      metadata
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
      DB.open do |db|
        record_to_parent = load_tree(db, resource_obj)
        connected_date = load_connected_date(db, resource_obj)
        connected_controlling_agency_dates = load_connected_controlling_agency_dates(db, resource_obj.id)

        record_to_parent.keys.each do |record_reference|
          next unless connected_date.has_key?(record_reference)

          record_start_date = DateParse.date_parse_down(connected_date.fetch(record_reference))

          all_controlling_dates = connected_controlling_agency_dates.fetch(record_reference, [])

          next_to_process = record_to_parent.fetch(record_reference, nil)
          while(!next_to_process.nil?) do
            all_controlling_dates += connected_controlling_agency_dates.fetch(next_to_process, [])
            break if next_to_process[0] == Resource
            next_to_process = record_to_parent[next_to_process]
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
            @gaps[record_reference] = {
              :ref => uri_for(record_reference),
              :gaps => gaps,
            }
          end
        end

        unless @gaps.empty?
          metadata = load_metadata(@gaps.keys)
          @gaps.keys.each do |reference|
            @gaps[reference].merge!(metadata.fetch(reference))
          end
        end
      end
    end

    def uri_for(reference)
      if reference[0] == ArchivalObject
        JSONModel::JSONModel(:archival_object).uri_for(reference[1], :repo_id => RequestContext.get(:repo_id))
      else
        JSONModel::JSONModel(:resource).uri_for(reference[1], :repo_id => RequestContext.get(:repo_id))
      end
    end
  end

  def calculate_gaps_in_control!
    gap_analyzer = GapAnalysis.new
    gap_analyzer.call(self)
    gap_analyzer.gaps.values.map {|gap_description|
      gap_description.merge(:gaps => gap_description[:gaps].map {|gap|
        {
          'start_date' => gap.start_date.strftime('%Y-%m-%d'),
          'end_date' => gap.end_date.strftime('%Y-%m-%d'),
        }
      })
    }
  end
end
