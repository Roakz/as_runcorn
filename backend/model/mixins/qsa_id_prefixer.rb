module QSAIdPrefixer

  def self.included(base)
    base.extend(ClassMethods)
  end

  def qsa_id_prefixed
    self.class.qsa_id_prefixed(self.qsa_id)
  end

  module ClassMethods
    # Subclasses may wish to override this and the instance method
    # and use opts to customise how they build their prefixed qsa_ids
    # based on properties of the instance ... looking at you FileIssues
    def qsa_id_prefixed(qsa_id, opts = {})
      QSAId.prefixed_id_for(self, qsa_id)
    end

    def sequel_to_jsonmodel(objs, opts = {})
      jsons = super

      objs.zip(jsons).each do |obj, json|
        json['qsa_id'] ||= obj.qsa_id # this happens for models using the database id
        json['qsa_id_prefixed'] = obj.qsa_id_prefixed
      end

      jsons
    end
  end
end
