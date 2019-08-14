module AssessmentSeries

  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods
    def sequel_to_jsonmodel(objs, opts = {})
      jsons = super

      series_hash = series_for(objs)

      objs.zip(jsons).each do |obj, json|
        json['series'] = series_hash[obj.id].map do |series|
          {
            'ref' => JSONModel(:resource).uri_for(series[:id], :repo_id => RequestContext.get(:repo_id)),
            'title' => series[:title],
            'qsa_id' => series[:qsa_id],
            'qsa_id_prefixed' => QSAId.prefixed_id_for(Resource, series[:qsa_id]),
          }
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
          .left_join(:resource, Sequel.qualify(:resource, :id) => Sequel.qualify(:archival_object, :root_record_id))
          .select(:physical_representation__id,
                  Sequel.as(:resource__id, :series_id),
                  Sequel.as(:resource__title, :series_title),
                  Sequel.as(:resource__qsa_id, :series_qsa_id))
          .map{|row| [row[:id], {:id => row[:series_id], :title => row[:series_title], :qsa_id => row[:series_qsa_id]}]}.to_h

        ass_prep.map{|ass, preps| [ass, preps.map{|prep| prep_series[prep]}.uniq.compact]}.to_h
      end
    end
  end
end
