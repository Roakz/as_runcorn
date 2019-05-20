class ChargeableItem < Sequel::Model(:chargeable_item)
  include ASModel
  corresponds_to JSONModel(:chargeable_item)

  set_model_scope :global


  def self.dollars_to_cents(dollars)
    # FIXME: srsly
    dollars.gsub(/\D/, '').to_i
  end


  def self.display_price(cents)
    '$' + cents.to_s.ljust(3, '0').insert(-3, '.')
  end


  def update_from_json(json, opts = {}, apply_nested_records = true)

    if json['price_dollars']
      json['price_cents'] = ChargeableItem.dollars_to_cents(json['price_dollars'])
    end

    super
  end


  def self.create_from_json(json, opts = {})
    if json['price_dollars']
      json['price_cents'] = dollars_to_cents(json['price_dollars'])
    end

    super
  end


  def self.sequel_to_jsonmodel(objs, opts = {})
    jsons = super

    objs.zip(jsons).each do |obj, json|
      json['price_dollars'] = display_price(obj.price_cents)
    end

    jsons
  end

end
