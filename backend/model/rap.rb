class PhysicalRepresentation < Sequel::Model(:rap)
  include ASModel
  corresponds_to JSONModel(:rap)

  set_model_scope :repository


  def update_from_json(json, opts = {}, apply_nested_records = true)
    # do magic

    super
  end

  def self.sequel_to_jsonmodel(objs, opts = {})
    jsons = super

    # do magic

    jsons
  end

end
