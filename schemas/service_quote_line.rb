{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "version" => 1,
    "type" => "object",
    "properties" => {
      "charge_category" => {"type" => "string", "dynamic_enum" => "runcorn_charge_category"},
      "description" => {"type" => "string", "ifmissing" => "error"},
      "charge_per_unit_cents" => {"type" => "integer", "ifmissing" => "error"},
      "charge_per_unit_display" => {"type" => "string", "readonly" => "true"},
      "charge_quantity_unit" => {"type" => "string", "dynamic_enum" => "runcorn_charge_quantity_unit"},
      "quantity" => {"type" => "integer", "ifmissing" => "error"},
      "charge_cents" => {"type" => "integer", "readonly" => "true"},
      "charge_display" => {"type" => "string", "readonly" => "true"},
      "chargeable_item" => {
        "type" => "object",
        "subtype" => "ref",
        "properties" => {
          "ref" => {
            "type" => [{"type" => "JSONModel(:chargeable_item) uri"}]
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
