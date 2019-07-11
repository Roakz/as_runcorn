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

      "change_description" => {"type" => "string", "ifmissing" => "error"},
      "authorised_by" => {"type" => "string", "ifmissing" => "error"},
      "change_date" => {"type" => "string", "ifmissing" => "error"},
      "approved_by" => {"type" => "string", "ifmissing" => "error"},
      "internal_reference" => {"type" => "string", "ifmissing" => "error"},
    },
  },
}
