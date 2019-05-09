module Transfers

  def self.included(base)
    base.extend(ClassMethods)
  end


  def update_from_json(json, opts = {}, apply_nested_records = true)
    # no editing please
    json['transfer_id'] = self.transfer_id
    super
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

    def create_from_json(json, opts = {})
      if json['transfer']
        json['transfer_id'] = json['transfer']['ref'].split('/').last.to_i
      end
      super
    end
  end
end
