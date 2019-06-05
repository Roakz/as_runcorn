{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "version" => 1,
    "type" => "object",

    "properties" => {
      "storage_location_id" => {"type"=> "number"},
      "storage_location" => {
        "type" => "object",
        "subtype" => "ref",
        "properties" => {
          "ref" => {"type" => "JSONModel(:location) uri"},
          "_resolved" => {
            "type" => "object",
            "readonly" => "true"
          }
        }
      },

      "functional_location" => {"type" => "string", "dynamic_enum" => "runcorn_location"},

      "context_uri" => {"type" => "string", "maxLength" => 255},
      "move_context" => {
        "type" => "object",
        "subtype" => "ref",
        "properties" => {
          "ref" => {"type" => ["JSONModel(:file_issue) uri", "JSONModel(:assessment) uri"]},
          "_resolved" => {
            "type" => "object",
            "readonly" => "true"
          }
        }
      },

      "user" => {"type" => "string", "maxLength" => 255, "ifmissing" => "error"},
      "move_date" => {"type" => "date", "minLength" => 1, "ifmissing" => "error"},
    },
  },
}
