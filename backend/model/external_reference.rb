class ExternalReference < Sequel::Model(:external_reference)
  include ASModel
  corresponds_to JSONModel(:external_reference)

  set_model_scope :global
end
