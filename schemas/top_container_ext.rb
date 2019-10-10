{
  "current_location" => {"type" => "string", "dynamic_enum" => "runcorn_location", "default" => "HOME"},
  "movements" => {"type" => "array", "items" => {"type" => "JSONModel(:movement) object"}},
  "move_to_storage_permitted" => {"type" => "boolean", "readonly" => "true"},

  "contents_count" => {"type" => "integer", "readonly" => "true"},
  "absent_contents_count" => {"type" => "integer", "readonly" => "true"},
  "absent_contents" => {
    "type" => "array",
    "items" => {
      "type" => "object",
      "subtype" => "ref",
      "properties" => {
        "ref" => {
          "type" => [{"type" => "JSONModel(:physical_representation) uri"}],
          "readonly" => "true"
        },
        "current_location" => {
          "type" => "string",
          "readonly" => "true"
        },

        "title" => {
          "type" => "string",
          "readonly" => "true"
        },

        "_resolved" => {
          "type" => "object",
          "readonly" => "true"
        }
      }
    }
  },
}
