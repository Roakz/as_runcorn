class ItemUse < Sequel::Model(:item_use)
  include ASModel
  corresponds_to JSONModel(:item_use)

  set_model_scope :repository

  def self.sequel_to_jsonmodel(objs, opts = {})
    jsons = super

    objs.zip(jsons).each do |obj, json|
      if  obj.physical_representation_id
        rep_uri = JSONModel(:physical_representation).uri_for(obj.physical_representation_id, :repo_id => obj.repo_id)
        rep_qsa_id =  QSAId.prefixed_id_for(PhysicalRepresentation, obj.physical_representation_id)
      else
        rep_uri = JSONModel(:digital_representation).uri_for(obj.digital_representation_id, :repo_id => obj.repo_id)
        rep_qsa_id =  QSAId.prefixed_id_for(DigitalRepresentation, obj.digital_representation_id)
      end

      json['representation'] = {'ref' => rep_uri, 'qsa_id' => rep_qsa_id}
      json['display_string'] = "%s used in %s (%s) at %s" % [rep_qsa_id,
                                                             obj.use_identifier,
                                                             obj.status,
                                                             [obj.start_date, obj.end_date].compact.join('--')
                                                            ]
    end

    jsons
  end


  def self.create_from_json(json, extra_values = {})
    extras = {}
    parsed_rep_ref = JSONModel.parse_reference(json['representation']['ref'])

    extras[parsed_rep_ref[:type] + '_id'] = parsed_rep_ref[:id]

    super(json, extra_values.merge(extras))
  end


  def self.save_uses(uses)
    ASUtils.wrap(uses).each do |use|
      rep_uri = JSONModel.parse_reference(use.representation['ref'])
      rep_id = rep_uri[:id]
      rep_type = rep_uri[:type]

      repo_uri = rep_uri[:repository]
      repo_id = JSONModel.parse_reference(repo_uri)[:id]

      RequestContext.open(:repo_id => repo_id) do
        use_row = ItemUse.filter(:"#{rep_type}_id" => rep_id,
                                 :use_identifier => use['use_identifier']).first

        if use_row
          ItemUse[use_row[:id]].update_from_json(use,
                                                 :"#{rep_type}_id" => rep_id,
                                                 :lock_version => use_row[:lock_version])
        else
          ItemUse.create_from_json(use,
                                   :"#{rep_type}_id" => rep_id)
        end
      end
    end
  end


  def self.csv(params)

  end
end
