module Transfers

  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods
    def sequel_to_jsonmodel(objs, opts = {})
      jsons = super

      objs.zip(jsons).each do |obj, json|
        if obj.transfer_id
          json['transfer'] = {'ref' => "/transfers/#{obj.transfer_id}"}
        end
      end

      jsons
    end
  end
end
