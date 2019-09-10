{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "version" => 1,
    "type" => "object",
    "properties" => {
      "raps" => {
        "type" => "array",
        "items" => {
          "type" => "object",
          "properties" => {
            "default_repo_rap" => {"type" => "boolean"},
            "rap" => {
              "type" => "object",
              "subtype" => "ref",
              "properties" => {
                "ref" => {"type" => "JSONModel(:rap) uri"},
              },
            },
            "attached_to" => {
              "type" => "object",
              "subtype" => "ref",
              "properties" => {
                "ref" => {"type" => [{"type" => "JSONModel(:repository) uri"},
                                     {"type" => "JSONModel(:resource) uri"},
                                     {"type" => "JSONModel(:archival_object) uri"},
                                     {"type" => "JSONModel(:digital_representation) uri"},
                                     {"type" => "JSONModel(:physical_representation) uri"}]},
              },
            },
            "item_count" => { "type" => "number" },
            "digital_representation_count" => { "type" => "number" },
            "physical_representation_count" => { "type" => "number" },
          }
        }
      },
    },
  },
}
