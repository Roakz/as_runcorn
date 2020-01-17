{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "version" => 1,
    "type" => "object",
    "properties" => {
      "status" => {"type" => "string", "readonly" => "true"},

      "start_date" => {"type" => "string"},
      "end_date" => {"type" => "string"},

      "treatment_process" => {"type" => "string"},
      "materials_used_consumables" => {"type" => "string"},
      "materials_used_staff_time" => {"type" => "string"},
      "treatments_applied" => {"type" => "string"},

      "external_reference" => {"type" => "string"},

      "treatment_batch_id" => {"type" => "string"},

      "user" => {
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

      "assessment" => {
        "type" => "object",
        "subtype" => "ref",
        "properties" => {
          "ref" => {
            "type" => [{"type" => "JSONModel(:assessment) uri"}],
            "ifmissing" => "error"
          },
          "_resolved" => {
            "type" => "object",
            "readonly" => "true"
          }
        }
      },
    },
  },
}
