class ItemUse < Sequel::Model(:item_use)
  include ASModel
  corresponds_to JSONModel(:item_use)

  set_model_scope :repository

  def self.sequel_to_jsonmodel(objs, opts = {})
    jsons = super

    objs.zip(jsons).each do |obj, json|
      prep_qsa_id = QSAId.prefixed_id_for(PhysicalRepresentation, obj.physical_representation_id)
      json['physical_representation'] = {'ref' => JSONModel(:physical_representation).uri_for(obj.physical_representation_id, :repo_id => obj.repo_id),
                                         'qsa_id' => prep_qsa_id}
      json['display_string'] = "%s used in %s (%s) at %s" % [prep_qsa_id,
                                                             obj.use_identifier,
                                                             obj.status,
                                                             [obj.start_date, obj.end_date].compact.join('--')
                                                            ]
    end

    jsons
  end


  def self.create_from_json(json, extra_values = {})
    extras = {}
    extras['physical_representation_id'] = JSONModel.parse_reference(json['physical_representation']['ref'])[:id]

    super(json, extra_values.merge(extras))
  end


  def self.save_uses(uses)
    ASUtils.wrap(uses).each do |use|
      prep_uri = JSONModel.parse_reference(use.physical_representation['ref'])
      prep_id = prep_uri[:id]

      repo_uri = prep_uri[:repository]
      repo_id = JSONModel.parse_reference(repo_uri)[:id]

      RequestContext.open(:repo_id => repo_id) do
        use_row = ItemUse.filter(:physical_representation_id => prep_id,
                                 :use_identifier => use['use_identifier']).first

        if use_row
          ItemUse[use_row[:id]].update_from_json(use,
                                                 :physical_representation_id => prep_id,
                                                 :lock_version => use_row[:lock_version])
        else
          ItemUse.create_from_json(use,
                                   :physical_representation_id => prep_id)
        end
      end
    end
  end
end
