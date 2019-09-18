class BatchAction < Sequel::Model(:batch_action)
  include ASModel
  corresponds_to JSONModel(:batch_action)

  set_model_scope :repository


  def self.sequel_to_jsonmodel(objs, opts = {})
    jsons = super

    objs.zip(jsons).each do |obj, json|
    end

    jsons
  end

end
