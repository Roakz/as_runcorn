module SeriesRetentionStatus

  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods
    def sequel_to_jsonmodel(objs, opts = {})
      jsons = super

      series_retention = build_series_map(objs)

      objs.zip(jsons).each do |obj, json|
        json['series_retention_status'] = series_retention[obj[series_id_col]]
      end

      jsons
    end

    def series_id_col
      @id_col_map ||= {
        ArchivalObject => :root_record_id,
        PhysicalRepresentation => :resource_id,
        DigitalRepresentation => :resource_id,
      }
      @id_col_map.fetch(self, :resource_id)
    end

    def build_series_map(objs)
      Resource
        .filter(:resource__id => objs.map{|o| o[series_id_col]})
        .left_join(Sequel.as(:enumeration_value, :retention_status), :retention_status__id => :resource__retention_status_id)
        .select(:resource__id, :retention_status__value)
        .map do |row|
        [row[:id], row[:value]]
      end.to_h
    end

  end

end
