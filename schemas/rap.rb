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

      "years" => {"type" => "integer", "ifmissing" => "error"},

      "change_description" => {"type" => "string", "ifmissing" => "error"},
      "authorised_by" => {"type" => "string", "ifmissing" => "error"},
      "change_date" => {"type" => "string", "ifmissing" => "error"},
      "approved_by" => {"type" => "string", "ifmissing" => "error"},
      "internal_reference" => {"type" => "string", "ifmissing" => "error"},

      "justification" => {"type" => "string"},
      "access_procedures" => {"type" => "string", "readonly" => "true"},

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
