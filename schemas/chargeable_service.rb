{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "version" => 1,
    "type" => "object",
    "uri" => "/chargeable_services",
    "properties" => {
      "uri" => {"type" => "string"},
      "name" => {"type" => "string", "ifmissing" => "error"},
      "description" => {"type" => "string", "ifmissing" => "error"},
      "last_revised_statement" => {"type" => "string"},

      "service_items" => {
        "type" => "array",
        "items" => {
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
    },
  },
}
