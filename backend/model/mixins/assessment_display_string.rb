module AssessmentDisplayString
  def self.prepended(base)
    class << base
      prepend(ClassMethods)
    end
  end

  module ClassMethods
    def sequel_to_jsonmodel(objs, opts = {})
      jsons = super

      objs.zip(jsons).each do |obj, json|
        json['display_string'] = json['qsa_id_prefixed']
      end

      jsons
    end

  end
end
