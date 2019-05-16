{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "version" => 1,
    "type" => "object",
    "uri" => "/chargeable_items",
    "properties" => {
      "uri" => {"type" => "string"},
      "description" => {"type" => "string", "ifmissing" => "error"},
      "price_cents" => {"type" => "integer", "ifmissing" => "error"},
      "price_dollars" => {"type" => "string"},
      "charge_quantity_unit" => {"type" => "string", "dynamic_enum" => "runcorn_charge_quantity_unit"},
    },
  },
}
