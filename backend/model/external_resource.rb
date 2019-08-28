class ExternalResource < Sequel::Model(:external_resource)
  include ASModel
  corresponds_to JSONModel(:external_resource)

  set_model_scope :global
end
