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


  def self.sequel_to_jsonmodel(objs, opts = {})
    jsons = super

    jsons.zip(objs).each do |json, obj|
      json['total_charge_cents'] = json['line_items'].map{|li| li['charge_cents']}.reduce(:+)
      json['total_charge_display'] = ChargeableItem.display_price(json['total_charge_cents'])
    end

    jsons
  end



end
