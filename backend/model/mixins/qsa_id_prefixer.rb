module QSAIdPrefixer

  def self.included(base)
    base.extend(ClassMethods)
  end

  def qsa_id_prefixed
    QSAId.prefixed_id_for(self.class, self.qsa_id)
  end

  module ClassMethods
    def sequel_to_jsonmodel(objs, opts = {})
      jsons = super

      objs.zip(jsons).each do |obj, json|
        json['qsa_id_prefixed'] = obj.qsa_id_prefixed
      end

      jsons
    end
  end
end
