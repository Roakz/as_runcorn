class BatchAction < Sequel::Model(:batch_action)
  include ASModel
  corresponds_to JSONModel(:batch_action)

  set_model_scope :repository

  define_relationship(:name => :batch_action_batch,
                      :json_property => 'batch',
                      :contains_references_to_types => proc {[Batch]},
                      :is_array => false)


  def self.sequel_to_jsonmodel(objs, opts = {})
    jsons = super

    objs.zip(jsons).each do |obj, json|
      json['action_time'] = obj.action_time.getlocal.iso8601 if obj.action_time
      json['approved_time'] = obj.action_time.getlocal.iso8601 if obj.approved_time
      json['display_string'] = "#{obj.qsa_id_prefixed}: #{I18n.t('batch_action_types.' + obj.action_type + '.label')}"
    end

    jsons
  end

end
