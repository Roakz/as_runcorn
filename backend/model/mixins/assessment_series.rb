module AssessmentSeries

  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods
    def sequel_to_jsonmodel(objs, opts = {})
      jsons = super

      series_hash = series_for(objs)

      objs.zip(jsons).each do |obj, json|
        json['series'] = series_hash[obj.id].map do |series_id|
          {'ref' => JSONModel(:resource).uri_for(series_id, :repo_id => RequestContext.get(:repo_id))}
        end
      end

      jsons
    end


    def series_for(objs)
      ass_prep = Assessment.find_relationship(:assessment)
                           .find_by_participants(objs)
                           .map {|obj, rels| [obj[:id], rels.map{|rel| rel[:physical_representation_id]}]}.to_h

      DB.open do |db|
        prep_series = db[:physical_representation].filter(:physical_representation__id => ass_prep.values.flatten)
          .left_join(:archival_object, Sequel.qualify(:archival_object, :id) => Sequel.qualify(:physical_representation, :archival_object_id))
          .select(:physical_representation__id, :archival_object__root_record_id).map{|row| [row[:id], row[:root_record_id]]}.to_h

        ass_prep.map{|ass, preps| [ass, preps.map{|prep| prep_series[prep]}.uniq]}.to_h
      end
    end
  end
end
