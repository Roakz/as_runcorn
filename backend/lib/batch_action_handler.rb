class BatchActionHandler

  class UnknownActionType < StandardError; end
  class InvalidParams < StandardError; end

  RegisteredHandler = Struct.new(:type,
                                 :models,
                                 :handler)

  def self.register(type, models)
    @@handlers ||= {}

    @@handlers[type] = RegisteredHandler.new(type, models, self)
  end


  def self.handler_for_type(type)
    (@@handlers[type.intern] or raise UnknownActionType.new(type)).handler
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
