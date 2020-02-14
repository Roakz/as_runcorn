{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "version" => 1,
    "type" => "object",
    "uri" => "/repositories/:repo_id/conservation_requests",
    "properties" => {
      "uri" => {"type" => "string"},

      "date_of_request" => {"type" => "string", "ifmissing" => "error"},
      "date_required_by" => {"type" => "string"},

      "requested_by" => {"type" => "string", "ifmissing" => "error"},
      "reason_requested" => {
        "type" => "string",
        "ifmissing" => "error",
        "dynamic_enum" => "conservation_request_reason"
      },

      "reason_requested_comments" => {"type" => "string"},

      "status" => {
        "type" => "string",
        "ifmissing" => "error",
        "dynamic_enum" => "conservation_request_status",
        "default" => "Draft",
      },

      "assessment" => {
        "type" => "object",
        "subtype" => "ref",
        "properties" => {
          "ref" => {
            "type" => [{"type" => "JSONModel(:assessment) uri"}],
          },
          "_resolved" => {
            "type" => "object",
            "readonly" => "true"
          }
        }
      },

      "requested_for" => {
        "type" => "string",
        "ifmissing" => "error",
        "dynamic_enum" => "conservation_request_requested_for"
      },

      "client_type" => {
        "type" => "string",
        "ifmissing" => "error",
        "dynamic_enum" => "conservation_request_client_type"
      },

      "client_name" => {"type" => "string"},
      "client_id" => {"type" => "string"},


      "display_string" => {
        "type" => "string",
        "readonly" => "true",
      },

      "linked_representation_count" => {
        "type" => "non_negative_integer",
        "readonly" => "true",
      },

      "migration_physical_representations" => {
        "type" => "array",
        "items" => {
          "type" => "object",
          "subtype" => "ref",
          "properties" => {
            "ref" => {
              "type" => [{"type" => "JSONModel(:physical_representation) uri"}],
            },
          }
        }
      }
    },
  },
}
