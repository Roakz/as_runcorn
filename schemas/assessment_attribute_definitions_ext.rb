# overriding the whole thing just to add a value to the type rnum
{
  "definitions" => {
    "type" => "array",
    "items" => {
      "type" => "object",
      "properties" => {
        "id" => { "type" => "integer" },
        "label" => { "type" => "string", "ifmissing" => "error" },
        "type" => { "enum" => ["rating", "format", "conservation_issue", "proposed_treatment"], "ifmissing" => "error" },
        "global" => { "type" => "boolean", "default" => false },
        "readonly" => { "type" => "boolean", "default" => false },
        "position" => { "type" => "integer", "readonly" => "true"},
      }
    }
  }
}
