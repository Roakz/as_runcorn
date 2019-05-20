class QuoteGenerator

  # subclass this to implement a quote generator
  # FIXME: this needs more explanation, init checking and a way to hook it up to the model

  def self.register(chargeable_service, model)
    @service = ChargeableService.filter(:name => chargeable_service).first
    @model = model
  end


  def self.rules
    @rules ||= {}
  end


  def self.add_rule(key, &block)
    raise 'No Service' unless @service && @model

    rules[key] = block
  end


  def self.quote_for(obj)
    raise 'No Service' unless @service && @model

    lines = []

    rules.keys.each do |key|
      lines << line_for(apply_rule(key, obj), chargeable_item_for(key).uri)
    end

    hash = {
      'chargeable_service' => {'ref' => @service.uri},
      'line_items' => lines
    }

    json = JSONModel::JSONModel(:service_quote).from_hash(hash, false, true)
    ServiceQuote.to_jsonmodel(ServiceQuote.create_from_json(json).id)
  end


  def self.apply_rule(key, obj)
    rules[key].call(obj)
  end


  def self.chargeable_item_for(name)
    ChargeableItem.filter(:name => name).first
  end


  def self.line_for(quantity, item_uri)
    {'quantity' => quantity, 'chargeable_item' => {'ref' => item_uri}}
  end
end
