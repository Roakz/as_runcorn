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

      "access_category" => {"type" => "string", "dynamic_enum" => "runcorn_access_category"},
      "current_location" => {"type" => "string", "dynamic_enum" => "runcorn_location"},
      "normal_location" => {"type" => "string", "dynamic_enum" => "runcorn_location"},

      "access_clearance_procedure" => {"type" => "string", "dynamic_enum" => "runcorn_access_clearance_procedure"},

      "accessioned_status" => {"type" => "string", "dynamic_enum" => "runcorn_accessioned_status"},

      "agency_assigned_id" => {"type" => "string"},

      "approval_date" => {"type" => "string"},
      "approved_by" => {
        "type" => "object",
        "subtype" => "ref",
        "properties" => {
          "ref" => {
            "type" => [{"type" => "JSONModel(:agent_person) uri"}],
            "ifmissing" => "error"
          },
          "_resolved" => {
            "type" => "object",
            "readonly" => "true"
          }
        }
      },

      "colour" => {"type" => "string", "dynamic_enum" => "runcorn_colour"},

      "deaccessions" => {"type" => "array", "items" => {"type" => "JSONModel(:deaccession) object"}},

      "description" => {"type" => "string"},

      "notes" => {
        "type" => "array",
        "items" => {"type" => [{"type" => "JSONModel(:note_multipart) object"},
                               {"type" => "JSONModel(:note_singlepart) object"}]},
      },

      "extents" => {"type" => "array", "items" => {"type" => "JSONModel(:extent) object"}},

      "file_issue_allowed" => {"type" => "boolean"},

      "format" => {"type" => "string", "dynamic_enum" => "runcorn_format"},

      "original_registration_date" => {"type" => "string"},

      "physical_description_type" => {"type" => "string", "dynamic_enum" => "runcorn_physical_description_type"},

      "preservation_restriction_status" => {"type" => "string", "dynamic_enum" => "runcorn_physical_preservation_restriction_status"},

      "external_ids" => {"type" => "array", "items" => {"type" => "JSONModel(:external_id) object"}},

      "title" => {"type" => "string"},

      "salvage_priority_code" => {"type" => "string", "dynamic_enum" => "runcorn_salvage_priority_code"},

      "sterilised_status" => {"type" => "boolean"},

      "publish" => {"type" => "boolean"},
    },
  },
}
