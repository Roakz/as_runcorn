{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "version" => 1,
    "type" => "object",
    "properties" => {
      "quantity" => {"type" => "integer", "ifmissing" => "error"},
      "charge_cents" => {"type" => "integer", "readonly" => "true"},
      "charge_display" => {"type" => "string", "readonly" => "true"},
      "chargeable_item" => {
        "type" => "object",
        "subtype" => "ref",
        "properties" => {
          "ref" => {
            "type" => [{"type" => "JSONModel(:chargeable_item) uri"}],
            "ifmissing" => "error"
          },
          "_resolved" => {
            "type" => "object",
            "readonly" => "true"
          }
        }
      }
    }
  }
}
