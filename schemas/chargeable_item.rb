{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "version" => 1,
    "type" => "object",
    "uri" => "/chargeable_items",
    "properties" => {
      "uri" => {"type" => "string"},
      "name" => {"type" => "string", "ifmissing" => "error"},
      "description" => {"type" => "string", "ifmissing" => "error"},
      "price_cents" => {"type" => "integer"},
      "price_dollars" => {"type" => "string", "ifmissing" => "error", "pattern" => "^\\$\\d+\\.\\d\\d$"},
      "charge_quantity_unit" => {"type" => "string", "dynamic_enum" => "runcorn_charge_quantity_unit"},
      "charge_category" => {"type" => "string", "dynamic_enum" => "runcorn_charge_category"},
    },
  },
}
