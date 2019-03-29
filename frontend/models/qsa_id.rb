class QSAId

  def self.models_hash
    @models ||= {}
  end

  def self.models
    models_hash.keys
  end


  def self.existing_id_for(model)
    models_hash[model]
  end


  def self.register(model, existing_id_field = false)
    if existing_id_field
      JSONModel(model).schema['properties'][existing_id_field.to_s].delete('ifmissing')
    end

    JSONModel(model).schema['properties']['qsa_id'] = {
      "type" => "integer",
      "readonly" => true
    }

    JSONModel(model).define_accessors(['qsa_id'])

    models_hash[model] = existing_id_field
  end

end
