{
  "disposal_class" => {"type" => "string"},
  "sensitivity_label" => {"type" => "string", "dynamic_enum" => "runcorn_sensitivity_label"},

  "approval_date" => {"type" => "string"},
  "approved_by" => {
    "type" => "object",
    "subtype" => "ref",
    "properties" => {
      "ref" => {
        "type" => [{"type" => "JSONModel(:agent_person) uri"}],
        "ifmissing" => "error"
      },
      "_resolved" => {
        "type" => "object",
        "readonly" => "true"
      }
    }
  },

  "physical_representations_count" => {"type"=> "number", "readonly" => "true"},
  "digital_representations_count" => {"type"=> "number", "readonly" => "true"},

  "significant_representations_counts" => {"type"=> "object", "readonly" => "true"},

  "all_existence_dates_range" => {"type"=> "string", "readonly" => "true"},

  "deaccessioned" => {"type" => "boolean", "readonly" => "true"},

  "rap_attached" => {"type" => "JSONModel(:rap) object"},

  "has_conservation_treatments_awaiting" => {"type" => "boolean", "readonly" => "true"},

  "archivist_approved" => {"type" => "boolean"},
  "copyright_status" => {"type" => "string", "dynamic_enum" => "runcorn_copyright_status"},
  "original_registration_date" => {"type" => "string"},
  "serialised" => {"type" => "boolean"},
  "information_sources" => {"type" => "string"},
  "abstract" => {"type" => "string"},
  "description" => {"type" => "string"},
  "retention_status" => {"type" => "string", "dynamic_enum" => "runcorn_retention_status"}
}
