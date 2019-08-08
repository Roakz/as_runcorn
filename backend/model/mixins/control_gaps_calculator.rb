module ControlGapsCalculator

  def self.included(base)
    base.extend(ClassMethods)
  end

  def gaps_in_control
    dates = DateCalculator.new(self, 'existence', true, :allow_open_end => true)

    record_start_date = DateParse.date_parse_down(dates.min_begin)

    controlling_relationships = self.class.control_relationship.definition.find_by_participant(self).select{|relationship| relationship[:jsonmodel_type] == 'series_system_agent_record_ownership_relationship'}

    all_date_ranges = controlling_relationships.map do |r|
      parsed_start = DateParse.date_parse_down(r.start_date)
      parsed_end = r.end_date ? DateParse.date_parse_up(r.end_date) : nil

      DateRange.new(parsed_start, parsed_end)
    end

    all_date_ranges.sort_by!(&:start_date)

    lifespan_start_date = record_start_date.nil? ? all_date_ranges.map(&:start_date).min : record_start_date
    lifespan_end_date = (all_date_ranges.map(&:start_date) + all_date_ranges.map(&:end_date).compact).max

    total_lifespan = [DateRange.new(lifespan_start_date, lifespan_end_date)]

    all_date_ranges.each do |control_date_range|
      next_lifespan = []
      total_lifespan.each do |lifespan_date_range|
        bits = lifespan_date_range.remove_range(control_date_range)
        next_lifespan.concat(bits)
      end
      total_lifespan = next_lifespan
      p ['total_lifespan', total_lifespan]
    end

    total_lifespan.sort_by(&:start_date)
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