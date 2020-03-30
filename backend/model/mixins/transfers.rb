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

      transfer_ids = objs.map(&:transfer_id).compact.uniq
      transfer_qsa_id_map = if transfer_ids.empty?
                              {}
                            else
                              Transfer
                                .filter(:id => transfer_ids)
                                .select(:id, :qsa_id)
                                .map {|row|
                                  [row[:id], row[:qsa_id]]
                                }.to_h
                            end

      objs.zip(jsons).each do |obj, json|
        if obj.transfer_id
          json['transfer'] = {'ref' => "/transfers/#{obj.transfer_id}"}
          json['transfer_qsa_id'] = QSAId.prefixed_id_for(Transfer, transfer_qsa_id_map.fetch(obj.transfer_id))
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
