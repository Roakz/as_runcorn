{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "version" => 1,
    "type" => "object",
    "uri" => "/repositories/:repo_id/batches",
    "properties" => {
      "uri" => {"type" => "string"},

      "note" => {"type" => "string"},

      "current_action" => {"type" => "object"},

      "actions" => {
        "type" => "array",
        "readonly" => "true",
        "items" => {
          "type" => "object",
          "subtype" => "ref",
          "properties" => {
            "ref" => {
              "type" => [{"type" => "JSONModel(:batch_action) uri"}],
              "readonly" => "true"
            },
            "_resolved" => {
              "type" => "object",
              "readonly" => "true"
            }
          }
        }
      },

      "status" => {
        "type" => "string",
        "dynamic_enum" => "runcorn_batch_status",
        "readonly" => "true",
      },

      "display_string" => {
        "type" => "string",
        "readonly" => "true",
      },

      "object_count" => {
        "type" => "non_negative_integer",
        "readonly" => "true",
      },
    },
  },
}
