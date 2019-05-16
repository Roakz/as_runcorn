class ChargeableService < Sequel::Model(:chargeable_service)
  include ASModel
  corresponds_to JSONModel(:chargeable_service)

  set_model_scope :global

  define_relationship(:name => :chargeable_service_item,
                      :json_property => 'service_items',
                      :contains_references_to_types => proc {[ChargeableItem]})


  def self.sequel_to_jsonmodel(objs, opts = {})
    jsons = super

    objs.zip(jsons).each do |obj, json|
    end

    jsons
  end

end
