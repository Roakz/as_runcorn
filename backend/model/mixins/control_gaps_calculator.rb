module ControlGapsCalculator

  class GapAnalysis
    attr_reader :gaps

    WorkItem = Struct.new(:obj, :inherited_control_ranges)

    def initialize
      @gaps = []
    end

    def call(resource_obj)
      # Ensure we process the broadest existence range for the resource
      # as determined the all_existence_dates mixin
      date_calculator = DateCalculator.new(resource_obj, 'existence', true, :allow_open_end => true)
      resource_obj.date.first.begin = date_calculator.min_begin

      queue = [WorkItem.new(resource_obj, [])]

      while !queue.empty?
        next_item = queue.shift
        obj = next_item.obj

        unless Array(obj.date).empty?
          record_start_date = DateParse.date_parse_down(obj.date.first.begin)
          relationship_defn = obj.class.control_relationship.definition

          agent_relationships = obj.cached_relationships.fetch(relationship_defn, [])

          controlling_relationships = Array(agent_relationships).select{|relationship| relationship[:jsonmodel_type] == 'series_system_agent_record_ownership_relationship'}
          obj_control_ranges = controlling_relationships.map do |r|
            parsed_start = DateParse.date_parse_down(r.start_date)
            parsed_end = r.end_date ? DateParse.date_parse_up(r.end_date) : nil
            DateRange.new(parsed_start, parsed_end)
          end

          lifespan_start_date = record_start_date
          lifespan_end_date = (obj_control_ranges.map(&:start_date) + obj_control_ranges.map(&:end_date).compact).max

          total_lifespan = DateRange.new(lifespan_start_date, lifespan_end_date)
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
        end

        find_children(obj).each do |child|
          queue << WorkItem.new(child, next_item.inherited_control_ranges + obj_control_ranges)
        end
      end
    end

    def find_children(obj)
      children = if obj.is_a?(Resource)
                   # Eager dates... & relationships
                   ArchivalObject.filter(:root_record_id => obj.id, :parent_id => nil).eager_graph(:date).all
                 else
                   ArchivalObject.filter(:root_record_id => obj.root_record_id, :parent_id => obj.id).eager_graph(:date).all
                 end

      ArchivalObject.eager_load_relationships(children, [ArchivalObject.control_relationship.definition])

      children
    end
  end

  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods
    def sequel_to_jsonmodel(objs, opts = {})
      jsons = super

      objs.zip(jsons).each do |obj, json|
        gap_analyzer = GapAnalysis.new
        gap_analyzer.call(obj)

        json['gaps_in_control'] = gap_analyzer.gaps.map {|gap_description|
          gap_description.merge(:gaps => gap_description[:gaps].map {|gap|
                                  {
                                    'start_date' => gap.start_date.strftime('%Y-%m-%d'),
                                    'end_date' => gap.end_date.strftime('%Y-%m-%d'),
                                  }
                                })
        }
      end

      jsons
    end
  end

end
