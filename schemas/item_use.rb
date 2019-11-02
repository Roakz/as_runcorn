{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "version" => 1,
    "type" => "object",
    "uri" => "/repositories/:repo_id/item_uses",

    "properties" => {
      "uri" => {"type" => "string"},
      
      "physical_representation" => {
        "type" => "object",
        "subtype" => "ref",
        "properties" => {
          "ref" => {"type" => "JSONModel(:physical_representation) uri"},
          "qsa_id" => {"type" => "string", "readonly" => "true"},
          "_resolved" => {
            "type" => "object",
            "readonly" => "true"
          }
        }
      },

      "item_use_type" => {"type" => "string", "maxLength" => 255, "ifmissing" => "error"},
      "use_identifier" => {"type" => "string", "maxLength" => 255, "ifmissing" => "error"},
      "status" => {"type" => "string", "maxLength" => 255, "ifmissing" => "error"},
      "used_by" => {"type" => "string", "maxLength" => 255, "ifmissing" => "error"},
      "start_date" => {"type" => "string", "maxLength" => 255, "ifmissing" => "error"},
      "end_date" => {"type" => "string", "maxLength" => 255},

      "display_string" => {"type" => "string", "readonly" => "true"},
    },
  },
}
