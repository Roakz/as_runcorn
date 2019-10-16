class MovementContextManager
  def self.add(model)
    JSONModel::JSONModel(:movement).schema['properties']['move_context']['properties']['ref']['type'] << {
      'type' => "JSONModel(:#{model}) uri"
    }
  end
end
