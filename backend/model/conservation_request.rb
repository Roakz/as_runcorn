class ConservationRequest < Sequel::Model(:conservation_request)
  include ASModel
  corresponds_to JSONModel(:conservation_request)

  set_model_scope :repository

  def add_representations(representation_model, *ids)
    backlink_col = :"#{representation_model.table_name}_id"

    DB.open do |db|
      db[:conservation_request_representations].multi_insert(ids.map {|id| {backlink_col => id, :conservation_request_id => self.id}})
    end
  end

end
