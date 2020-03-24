module WithinSets

  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods
    def sequel_to_jsonmodel(objs, opts = {})
      jsons = super

      series_qsa_ids = build_series_qsa_id_map(objs)
      parent_qsa_ids = build_parent_qsa_id_map(objs)

      objs.zip(jsons).each do |obj, json|
        json['within'] = []
        if parent_qsa_ids.fetch(obj.parent_id, false)
          json['within'] << parent_qsa_ids.fetch(obj.parent_id)
        end
        json['within'] << series_qsa_ids.fetch(obj.root_record_id).fetch(:qsa_id_prefixed)
        if obj.transfer_id
          json['within'] << QSAId.prefixed_id_for(Transfer, obj.transfer_id)
        end

        json['series_summary'] = series_qsa_ids.fetch(obj.root_record_id)
      end

      jsons
    end

    def build_series_qsa_id_map(objs)
      Resource
        .filter(:id => objs.map(&:root_record_id))
        .select(:id, :qsa_id, :title)
        .map do |row|
        [row[:id], {
           :qsa_id => row[:qsa_id],
           :qsa_id_prefixed => QSAId.prefixed_id_for(Resource, row[:qsa_id]),
           :title => row[:title]
         }]
      end.to_h
    end

    def build_parent_qsa_id_map(objs)
      ArchivalObject
        .filter(:id => objs.map(&:parent_id).compact.uniq)
        .select(:id, :qsa_id)
        .map do |row|
        [row[:id], QSAId.prefixed_id_for(ArchivalObject, row[:qsa_id])]
      end.to_h
    end
  end

end
