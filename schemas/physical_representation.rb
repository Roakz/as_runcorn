{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "version" => 1,
    "type" => "object",
    "uri" => "/repositories/:repo_id/physical_representations",
    "properties" => {
      "uri" => {"type" => "string"},

      "existing_ref" => { "type" => "JSONModel(:physical_representation) uri", "readonly" => true },
      "display_string" => {"type" => "string", "maxLength" => 8192, "readonly" => true},

      "description" => {"type" => "string"},
    },
  },
}
