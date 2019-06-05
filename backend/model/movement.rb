class Movement < Sequel::Model(:movement)
  include ASModel
  corresponds_to JSONModel(:movement)

  set_model_scope :global

  def self.sequel_to_jsonmodel(objs, opts = {})
    jsons = super

    objs.zip(jsons).each do |obj, json|
      if obj.context_uri
        json['move_context'] = {'ref' => obj.context_uri}
      end

      if obj.storage_location_id
        json['storage_location'] = {'ref' => JSONModel(:location).uri_for(obj.storage_location_id)}
      end
    end

    jsons
  end


  def self.create_from_json(json, opts = {})
    json['context_uri'] = json['move_context'] ? json['move_context']['ref'] : nil

    if json['storage_location']
      json['storage_location_id'] = json['storage_location']['ref'].split('/').last.to_i
    end

    super
  end

end
