class RAP < Sequel::Model(:rap)
  include ASModel
  corresponds_to JSONModel(:rap)

  set_model_scope :repository

  def update_from_json(json, opts = {}, apply_nested_records = true)
    result = super

    touch_attached_record_mtime

    result
  end

  def self.sequel_to_jsonmodel(objs, opts = {})
    jsons = super

    objs.zip(jsons).each do |obj, json|
      json['display_string'] = obj.build_display_string(json)
      RAPs.supported_models.each do |model|
        if obj[:"#{model.table_name}_id"]
          json['attached_to'] = {
            'ref' => model.get_or_die(obj[:"#{model.table_name}_id"]).uri
          }
        end
      end
      if json['attached_to'].nil? && obj[:default_for_repo_id]
        json['attached_to'] = {
          'ref' => JSONModel(:repository).uri_for(obj[:default_for_repo_id])
        }
      end

      json['is_repository_default'] = !!obj[:default_for_repo_id]
    end

    jsons
  end

  def build_display_string(json)
    [
      "%s years" % [json.years.to_s],
      json.open_access_metadata ? "Open metadata" : "Closed Metadata",
      json['access_status'],
      json['access_category'],
    ].join('; ')
  end

  def self.get_default_id
    repo_id = RequestContext.get(:repo_id)
    default = RAP[:default_for_repo_id => repo_id]

    if default.nil?
      default = RAP.create_from_json(JSONModel(:rap).from_hash(
                                       'open_access_metadata' => false,
                                       'access_status' => 'Restricted Access',
                                       'access_category' => 'N/A',
                                       'years' => 100,
                                       'change_description' => 'System default',
                                       'authorised_by' => 'admin',
                                       'change_date' => Date.today.iso8601,
                                       'approved_by' => 'admin',
                                       'internal_reference' => 'SYSTEM_DEFAULT_RAP',
                                     ),
                                    :default_for_repo_id => repo_id)
    end

    default.id
  end

  def touch_attached_record_mtime
    RAPs.supported_models.each do |model|
      if self[:"#{model.table_name}_id"]
        model.update_mtime_for_ids([self[:"#{model.table_name}_id"]])
      end
    end
  end
end
