class QSAId

  def self.models_hash
    @models ||= {}
  end


  def self.models
    models_hash.keys
  end


  def self.existing_id_for(model)
    models_hash[model][:existing_id_field]
  end


  def self.prefix_for(model)
    models_hash[model][:prefix]
  end


  def self.prefixed_id_for(model, id)
    prefix_for(model) + id.to_s
  end


  def self.model_for(prefix)
    # this carbunkle honours the dreadful situation with file_issues
    # where the prefix is extended depending on the issue_type
    # qsa_id was not designed to handle prefix variations based on
    # properties of individual objects, so here we are. sad. alone.
    #
    # if the prefix provided doesn't match any of the registered models
    # then keep trimming the last character off until it does.
    # it's a liberal, inclusive approach.
    while !prefix.empty?
      model = models_hash.select{|k,v| v[:prefix] == prefix}.keys.first
      return model if model
      prefix = prefix[0..-2]
    end
  end


  def self.parse_prefixed_id(prefixed_id)
    parsed = prefixed_id.scan(/([^\d]+)?(\d+)/)[0]
    return {} unless !!parsed
    return {} if parsed[0].nil?

    out = [:prefix, :id].zip(parsed).to_h
    out[:model] = self.model_for(out[:prefix])
    out
  end


  def self.ref_for(qsa_id, repo_id)
    parsed = parse_prefixed_id(qsa_id)
    return 'NOT A VALID QSA ID' if parsed.empty?

    parsed[:model].my_jsonmodel.uri_for(parsed[:model].filter(:qsa_id => parsed[:id]).get(:id), :repo_id => repo_id)
  end


  def self.mode(mode = false)
    @mode ||= :backend
    @mode = mode if mode
    @mode
  end


  def self.backend?
    self.mode == :backend
  end


  def self.register(model, opts = {})
    use_database_id = opts.fetch(:use_database_id, false)
    existing_id_field = opts.fetch(:existing_id_field, false)
    prefix = opts.fetch(:prefix, '')

    asmodel = ASModel.all_models.select{|m| m.has_jsonmodel? && m.my_jsonmodel.record_type == model.to_s}.first if QSAId.backend?

    if QSAId.backend?
      asmodel.include(QSAIdPrefixer)

      if use_database_id
        asmodel.def_column_alias(:qsa_id, :id)
      else
        # check that the sequence is good
        seq_name =  "QSA_ID_#{asmodel.table_name.upcase}"
        max_id = asmodel.max(:qsa_id) || 0
        DB.open do |db|
          if (current_seq = db[:sequence].filter(:sequence_name => seq_name).get(:value))
            if current_seq < max_id
              db[:sequence].filter(:sequence_name => seq_name).update(:value => max_id)
            end
          else
            db[:sequence].insert(:sequence_name => seq_name, :value => max_id)
          end
        end

        asmodel.include(AutoGenerator)
        asmodel.auto_generate :property => :qsa_id,
                              :generator => proc { |json| Sequence.get("QSA_ID_#{asmodel.table_name.upcase}") },
                              :only_on_create => true
      end
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

    JSONModel::JSONModel(model).schema['properties']['qsa_id_prefixed'] = {
      "type" => "string",
      "readonly" => true
    }

    JSONModel::JSONModel(model).define_accessors(['qsa_id'])
    JSONModel::JSONModel(model).define_accessors(['qsa_id_prefixed'])

    models_hash[QSAId.backend? ? asmodel : model] = {:existing_id_field => existing_id_field, :prefix => prefix}
  end

end
