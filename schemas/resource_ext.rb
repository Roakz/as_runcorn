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

  "all_existence_dates_range" => {"type"=> "string", "readonly" => "true"},
}
