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


  def self.create_from_json(json, extra_values = {})
    json['context_uri'] = json['move_context'] ? json['move_context']['ref'] : nil

    extras = {}

    if json['storage_location']
      extras['storage_location_id'] = JSONModel.parse_reference(json['storage_location']['ref'])[:id]
    end

    super(json, extra_values.merge(extras))
  end

end
