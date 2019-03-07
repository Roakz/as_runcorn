class QSAId

  def self.register(model, existing_id_field = false)
    model.instance_eval do
      model.include(AutoGenerator)

      model.auto_generate :property => :qsa_id,
                          :generator => proc { |json| Sequence.get("QSA_ID_#{model.table_name.upcase}") },
                          :only_on_create => true

      if existing_id_field
        model.my_jsonmodel.schema['properties'][existing_id_field.to_s].delete('ifmissing')

        model.auto_generate :property => existing_id_field,
                            :generator => proc { |json| json['qsa_id'].to_s },
                            :only_on_create => true
      end

      model.my_jsonmodel.schema['properties']['qsa_id'] = {
        "type" => "integer",
        "readonly" => true
      }
    end
  end

end
