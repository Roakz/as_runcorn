class ServiceQuote < Sequel::Model(:service_quote)
  include ASModel
  corresponds_to JSONModel(:service_quote)

  set_model_scope :global

  one_to_many :service_quote_line, :class => "ServiceQuoteLine"

  def_nested_record(:the_property => :line_items,
                    :contains_records_of_type => :service_quote_line,
                    :corresponding_to_association => :service_quote_line)

  define_relationship(:name => :service_quote_service,
                      :json_property => 'chargeable_service',
                      :contains_references_to_types => proc {[ChargeableService]},
                      :is_array => false)


  def self.create_from_json(json, opts = {})
    # initialize lines from predefined chargeable items
    json['line_items'].each do |item|
      if item['chargeable_item']
        chargeable_item = ServiceQuote.chargeable_item(item['chargeable_item']['ref'])

        item['description'] ||= chargeable_item['description']
        item['charge_quantity_unit'] ||= chargeable_item['charge_quantity_unit']
        item['charge_category'] ||= chargeable_item['charge_category']
        item['charge_per_unit_cents'] ||= chargeable_item['price_cents']
      end
    end

    super
  end

  def self.sequel_to_jsonmodel(objs, opts = {})
    jsons = super

    jsons.zip(objs).each do |json, obj|
      json['total_charge_cents'] = json['line_items'].map{|li| li['charge_cents']}.reduce(:+)
      json['total_charge_display'] = ChargeableItem.display_price(json['total_charge_cents'])
    end

    jsons
  end


  def self.chargeable_item(uri)
    ChargeableItem.to_jsonmodel(ChargeableItem[JSONModel.parse_reference(uri)[:id]])
  end


  def issue
    self.issued_date = Time.now
    self.save
  end


  def withdraw
    self.issued_date = nil
    self.save
  end


  def issued?
    !!self.issued_date
  end
end
