module RAPsApplied

  def self.included(base)
    base.extend(ClassMethods)
  end

  class RAPApplications

    def initialize(objs)
      @rap_applied_by_representation_id = {}
      @active_raps_by_id = {}

      load!(objs)
    end

    def rap_json_for_representation(representation_id)
      active_rap = @rap_applied_by_representation_id.fetch(representation_id, []).find {|rap_applied| rap_applied[:is_active] == 1}

      raise "ASSERTION FAILED: No active rap for #{representation_id}" unless active_rap

      @active_raps_by_id.fetch(active_rap[:rap_id])
    end

    def rap_history_for_representation(representation_id)
      @rap_applied_by_representation_id.fetch(representation_id, [])
        .sort_by {|rap_applied| rap_applied[:version]}
        .map {|rap_applied|
        {
          'ref' => JSONModel::JSONModel(:rap).uri_for(rap_applied[:rap_id], { :repo_id => RequestContext.get(:repo_id) }),
          'version' => rap_applied[:version],
          'is_active' => rap_applied[:is_active] == 1,
        }
      }
    end

    private

    def load!(representation_objs)
      backlink_col = :"#{representation_objs[0].class.table_name}_id"

      DB.open do |db|
        rap_id_to_representation_ids = {}

        db[:rap_applied].filter(backlink_col => representation_objs.map(&:id)).each do |row|
          @rap_applied_by_representation_id[row[backlink_col]] ||= []
          @rap_applied_by_representation_id[row[backlink_col]] << row
        end

        active_rap_ids = @rap_applied_by_representation_id.values
                           .flatten
                           .select {|row| row[:is_active] == 1}
                           .map {|row| row[:rap_id]}
                           .uniq

        RAP.sequel_to_jsonmodel(RAP.filter(:id => active_rap_ids).all).each do |rap|
          @active_raps_by_id[rap.id] = rap
        end
      end
    end
  end

  module ClassMethods
    def sequel_to_jsonmodel(objs, opts = {})
      begin
        jsons = super

        return jsons if objs.empty?

        raps = RAPApplications.new(objs)

        objs.zip(jsons).each do |obj, json|
          json['rap_applied'] = raps.rap_json_for_representation(obj.id)
          json['rap_history'] = raps.rap_history_for_representation(obj.id)
        end

        jsons
      rescue
        $stderr.puts($!)
        $stderr.puts($@.join("\n"))
      end
    end
  end

end
