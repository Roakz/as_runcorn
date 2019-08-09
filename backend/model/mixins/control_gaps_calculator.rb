module ControlGapsCalculator

  class GapAnalysis
    attr_reader :gaps

    def initialize
      @gaps = {}
    end

    def call(objs)
      calculate_gaps_in_control(objs, [])
    end

    def calculate_gaps_in_control(objs, inherited_controls = [])
      objs.each do |obj|
        record_start_date = DateParse.date_parse_down(obj.date.first.begin)
        controlling_relationships = objs.class.control_relationship.definition.find_by_participant(obj).select{|relationship| relationship[:jsonmodel_type] == 'series_system_agent_record_ownership_relationship'}

        all_control_ranges = controlling_relationships.map do |r|
          parsed_start = DateParse.date_parse_down(r.start_date)
          parsed_end = r.end_date ? DateParse.date_parse_up(r.end_date) : nil
          DateRange.new(parsed_start, parsed_end)
        end

        all_control_ranges.sort_by!(&:start_date)

        lifespan_start_date = record_start_date
        lifespan_end_date = (all_control_ranges.map(&:start_date) + all_control_ranges.map(&:end_date).compact).max

        total_lifespan = DateRange.new(lifespan_start_date, lifespan_end_date)
        gaps = [total_lifespan]

        (inherited_controls + all_control_ranges).each do |control_date_range|
          next_lifespan = []
          gaps.each do |lifespan_date_range|
            bits = lifespan_date_range.remove_range(control_date_range)
            next_lifespan.concat(bits)
          end
          gaps = next_lifespan
        end

        @gaps[obj.uri] = gaps
      end
    end
  end

  def self.included(base)
    base.extend(ClassMethods)
  end

  def gaps_in_control(inherited_controls = [])
    record_start_date = DateParse.date_parse_down(date.first.begin)

    controlling_relationships = self.class.control_relationship.definition.find_by_participant(self).select{|relationship| relationship[:jsonmodel_type] == 'series_system_agent_record_ownership_relationship'}

    all_control_ranges = controlling_relationships.map do |r|
      parsed_start = DateParse.date_parse_down(r.start_date)
      parsed_end = r.end_date ? DateParse.date_parse_up(r.end_date) : nil

      DateRange.new(parsed_start, parsed_end)
    end

    all_control_ranges.sort_by!(&:start_date)

    lifespan_start_date = record_start_date
    lifespan_end_date = (all_control_ranges.map(&:start_date) + all_control_ranges.map(&:end_date).compact).max

    total_lifespan = DateRange.new(lifespan_start_date, lifespan_end_date)
    gaps = [total_lifespan]

    (inherited_controls + all_control_ranges).each do |control_date_range|
      next_lifespan = []
      gaps.each do |lifespan_date_range|
        bits = lifespan_date_range.remove_range(control_date_range)
        next_lifespan.concat(bits)
      end
      gaps = next_lifespan
    end

    gaps.sort_by(&:start_date)
  end

  module ClassMethods
    def sequel_to_jsonmodel(objs, opts = {})
      jsons = super

      objs.zip(jsons).each do |obj, json|
        json['gaps_in_control'] = obj.gaps_in_control.map{|date_range|
          {
            'start_date' => date_range.start_date.strftime('%Y-%m-%d'),
            'end_date' => date_range.end_date.strftime('%Y-%m-%d'),
          }
        }
      end

      jsons
    end
  end

end