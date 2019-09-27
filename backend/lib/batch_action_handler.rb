class BatchActionHandler

  class UnknownActionType < StandardError; end
  class InvalidParams < StandardError; end

  RegisteredHandler = Struct.new(:type,
                                 :description,
                                 :models,
                                 :handler)

  def self.register(type, description, models)
    @@handlers ||= {}

    @@handlers[type] = RegisteredHandler.new(type, description, models, self)
  end


  def self.handlers
    @@handlers ||= {}

    @@handlers.values.map{|h| h.to_h}
  end


  def self.handler_for_type(type)
    registration_for_type(type).handler
  end


  def self.models_for_type(type)
    registration_for_type(type).models
  end


  def self.registration_for_type(type)
    (@@handlers[type.intern] or raise UnknownActionType.new(type))
  end


  def self.default_params
    raise NotImplementedError.new("This method must be overriden by the implementing class")
  end


  def self.validate_params(params)
    raise NotImplementedError.new("This method must be overriden by the implementing class")
  end


  def self.perform_action(params, user, action_uri, uris)
    raise NotImplementedError.new("This method must be overriden by the implementing class")
  end
end
