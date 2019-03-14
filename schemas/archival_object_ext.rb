{
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
}
