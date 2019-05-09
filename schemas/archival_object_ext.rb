{
  "description" => {"type" => "string"},
  "access_clearance_procedure" => {"type" => "string", "dynamic_enum" => "runcorn_access_clearance_procedure"},
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

  "physical_representations" => {
    "type" => "array",
    "items" => {"type" => "JSONModel(:physical_representation) object"}
  },
  "digital_representations" => {
    "type" => "array",
    "items" => {"type" => "JSONModel(:digital_representation) object"}
  },

  "physical_representations_count" => {"type"=> "number", "readonly" => "true"},
  "digital_representations_count" => {"type"=> "number", "readonly" => "true"},

  "transfer" => {
    "type" => "object",
    "subtype" => "ref",
    "properties" => {
      "ref" => {
        "type" => [{"type" => "JSONModel(:transfer) uri"}],
        "ifmissing" => "error"
      },
      "_resolved" => {
        "type" => "object",
        "readonly" => "true"
      }
    }
  },
}
