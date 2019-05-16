class ServiceQuoteLine < Sequel::Model(:service_quote_line)
  include ASModel
  corresponds_to JSONModel(:service_quote_line)

  set_model_scope :global

  define_relationship(:name => :service_quote_line_item,
                      :json_property => 'chargeable_item',
                      :contains_references_to_types => proc {[ChargeableItem]},
                      :is_array => false)

  def self.sequel_to_jsonmodel(objs, opts = {})
    jsons = super

    jsons.zip(objs).each do |json, obj|
      json['charge_cents'] = obj.calculate_charge
      json['charge_display'] = ChargeableItem.display_price(json['charge_cents'])
    end

    jsons
  end


  def calculate_charge
    self.quantity *
    db[:service_quote_line_item_rlshp]
      .filter(:service_quote_line_id => self.id)
      .left_join(:chargeable_item, :service_quote_line_item_rlshp__chargeable_item_id => :chargeable_item__id)
      .get(Sequel.qualify(:chargeable_item, :price_cents))
  end

end
