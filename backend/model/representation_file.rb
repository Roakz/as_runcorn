class RepresentationFile < Sequel::Model(:representation_file)
  include ASModel
  corresponds_to JSONModel(:representation_file)

  set_model_scope :repository
end
