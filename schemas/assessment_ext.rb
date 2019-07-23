{
  "records" => {
    "type" => "array",
    "ifmissing" => "error",
    "minItems" => 1,
    "items" => {
      "type" => "object",
      "subtype" => "ref",
      "properties" => {
        "ref" => {
          "type" => [{"type" => "JSONModel(:physical_representation) uri"}],
          "ifmissing" => "error"
        },
        "_resolved" => {
          "type" => "object",
          "readonly" => "true"
        }
      }
    }
  },
  "external_ids" => {"type" => "array", "items" => {"type" => "JSONModel(:external_id) object"}},
  "treatment_priority" => {"type" => "string", "dynamic_enum" => "runcorn_treatment_priority"},
}
