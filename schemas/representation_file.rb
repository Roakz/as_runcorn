{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "version" => 1,
    "type" => "object",
    "properties" => {
      "key" => {"type" => "string", "ifmissing" => "error"},
      "mime_type" => {"type" => "string", "ifmissing" => "error"},
    },
  },
}
