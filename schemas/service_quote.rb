{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "version" => 1,
    "type" => "object",
    "uri" => "/service_quotes",
    "properties" => {
      "uri" => {"type" => "string"},

      "issued_date" => {"type" => "date", "readonly" => "true"},
      "total_charge_cents" => {"type" => "integer", "readonly" => "true"},
      "total_charge_display" => {"type" => "string", "readonly" => "true"},
      "chargeable_service" => {
        "type" => "object",
        "subtype" => "ref",
        "properties" => {
          "ref" => {
            "type" => [{"type" => "JSONModel(:chargeable_service) uri"}],
            "ifmissing" => "error"
          },
          "_resolved" => {
            "type" => "object",
            "readonly" => "true"
          }
        }
      },
      "line_items" => {"type" => "array", "items" => {"type" => "JSONModel(:service_quote_line) object"}},
    },
  },
}
