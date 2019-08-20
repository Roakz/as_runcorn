module ControlGapsCalculator

  class GapAnalysis
    attr_reader :gaps

    RootWorkItem = Struct.new(:resource_obj) do
      def fetch_records
        [self.resource_obj]
      end

      def inherited_control_ranges
        []
      end

      def next_work_items(record_control_ranges)
        ArchivalObject.filter(:root_record_id => self.resource_obj.id, :parent_id => nil)
          .select(:id)
          .map {|row| row[:id]}
          .each_slice(200)
          .map {|ids| WorkItem.new(ArchivalObject, ids, record_control_ranges.fetch(self.resource_obj.id, []))}
      end
    end

    # A chunk of work that needs to be performed against a set of records with a common parent.
    WorkItem = Struct.new(:record_model, :record_ids, :inherited_control_ranges) do
      def fetch_records
        records = ArchivalObject.filter(Sequel.qualify(:archival_object, :id) => self.record_ids).eager_graph(:date).all
        ArchivalObject.eager_load_relationships(records, [ArchivalObject.control_relationship.definition])
        records
      end

      def next_work_items(record_control_ranges)
        children = {}

        # Find the children of this work item's records and emit work items for
        # them.
        ArchivalObject
          .filter(:parent_id => self.record_ids)
          .select(:parent_id, :id)
          .each do |row|
          children[row[:parent_id]] ||= []
          children[row[:parent_id]] << row[:id]
        end

        children.flat_map {|parent_id, child_ids|
          child_ids.each_slice(200).map {|ids|
            WorkItem.new(ArchivalObject, ids, self.inherited_control_ranges + record_control_ranges.fetch(parent_id, []))
          }
        }
      end
    end

    def initialize
      @gaps = []
    end

    def call(resource_obj)
      # Ensure we process the broadest existence range for the resource
      # as determined the all_existence_dates mixin
      date_calculator = DateCalculator.new(resource_obj, 'existence', true, :allow_open_end => true)
      resource_obj.date.first.begin = date_calculator.min_begin

      Resource.eager_load_relationships([resource_obj], [Resource.control_relationship.definition])

      queue = [RootWorkItem.new(resource_obj)]

      while !queue.empty?
        next_item = queue.shift
        record_control_ranges = {}

        # For each record in our work set, calculate any gaps in control and
        # accumulate their controlling relationships.
        next_item.fetch_records.each do |obj|
          unless Array(obj.date).empty?
            record_start_date = obj.date.find(&:begin)
            record_start_date = DateParse.date_parse_down(record_start_date.begin) if record_start_date

            next unless record_start_date

            relationship_defn = obj.class.control_relationship.definition

            agent_relationships = obj.cached_relationships.fetch(relationship_defn, [])

            controlling_relationships = Array(agent_relationships).select{|relationship| relationship[:jsonmodel_type] == 'series_system_agent_record_ownership_relationship'}
            obj_control_ranges = controlling_relationships.map do |r|
              parsed_start = DateParse.date_parse_down(r.start_date)
              parsed_end = r.end_date ? DateParse.date_parse_up(r.end_date) : nil
              DateRange.new(parsed_start, parsed_end)
            end

            total_lifespan = DateRange.new(record_start_date, nil)
            gaps = [total_lifespan]

            (next_item.inherited_control_ranges + obj_control_ranges).each do |control_date_range|
              next_lifespan = []
              gaps.each do |lifespan_date_range|
                bits = lifespan_date_range.remove_range(control_date_range)
                next_lifespan.concat(bits)
              end
              gaps = next_lifespan
            end

            unless gaps.empty?
              @gaps << {
                :ref => obj.uri,
                :gaps => gaps,
                :qsa_id => obj.qsa_id_prefixed,
                :display_string => obj[:display_string] || obj[:title],
              }
            end

            record_control_ranges[obj.id] = obj_control_ranges
          end
        end

        queue.concat(next_item.next_work_items(record_control_ranges))
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
