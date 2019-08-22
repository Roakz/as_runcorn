{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "version" => 1,
    "type" => "object",
    "uri" => "/repositories/:repo_id/raps",
    "properties" => {
      "uri" => {"type" => "string"},

      "open_access_metadata" => {"type" => "boolean"},
      "access_status" => {"type" => "string", "dynamic_enum" => "runcorn_rap_access_status", "ifmissing" => "error"},
      "access_category" => {"type" => "string", "dynamic_enum" => "runcorn_rap_access_category", "ifmissing" => "error"},

      "years" => {"type" => "non_negative_integer"},

      "internal_reference" => {"type" => "string", "ifmissing" => "error"},

      "notice_date" => {"type" => "string"},

      "justification" => {"type" => "string"},

      "display_string" => {"type" => "string", "readonly" => "true"},

      "is_repository_default" => {"type" => "boolean", "readonly" => "true"},

      "attached_to" => {
        "type" => "object",
        "subtype" => "ref",
        "properties" => {
          "ref" => {
            "type" => [{"type" => "JSONModel(:repository) uri"},
                       {"type" => "JSONModel(:resource) uri"},
                       {"type" => "JSONModel(:archival_object) uri"},
                       {"type" => "JSONModel(:digital_representation) uri"},
                       {"type" => "JSONModel(:physical_representation) uri"}]
          }
        }
      },
    },
  },
}
