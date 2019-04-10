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


  def self.mode(mode = false)
    @mode ||= :backend
    @mode = mode if mode
    @mode
  end


  def self.backend?
    self.mode == :backend
  end


  def self.register(model, existing_id_field = false)
    asmodel = ASModel.all_models.select{|m| m.has_jsonmodel? && m.my_jsonmodel.record_type == model.to_s}.first if QSAId.backend?

    if QSAId.backend?
      asmodel.include(AutoGenerator)

      asmodel.auto_generate :property => :qsa_id,
                            :generator => proc { |json| Sequence.get("QSA_ID_#{asmodel.table_name.upcase}") },
                            :only_on_create => true
    end

    if existing_id_field
      JSONModel::JSONModel(model).schema['properties'][existing_id_field.to_s].delete('ifmissing')

      if QSAId.backend?
        asmodel.auto_generate :property => existing_id_field,
                              :generator => proc { |json| json['qsa_id'].to_s },
                              :only_if => proc { |json| json['qsa_id'] }
      end
    end

    JSONModel::JSONModel(model).schema['properties']['qsa_id'] = {
      "type" => "integer",
      "readonly" => true
    }

    JSONModel::JSONModel(model).define_accessors(['qsa_id'])

    models_hash[QSAId.backend? ? asmodel : model] = existing_id_field
  end

end
