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

      "current_location" => {"type" => "string", "dynamic_enum" => "runcorn_location", "ifmissing" => "error"},

      "normal_location" => {"type" => "string", "dynamic_enum" => "runcorn_location", "ifmissing" => "error"},

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

      "contained_within" => {"type" => "string", "dynamic_enum" => "runcorn_physical_representation_contained_within"},

      "containers" => {"type" => "array", "items" => {"type" => "JSONModel(:sub_container) object"}},

      "deaccessions" => {"type" => "array", "items" => {"type" => "JSONModel(:deaccession) object"}},

      "description" => {"type" => "string"},

      "exhibition_history" => {"type" => "string"},

      "exhibition_notes" => {"type" => "string"},

      "exhibition_quality" => {"type" => "boolean"},

      "extents" => {"type" => "array", "items" => {"type" => "JSONModel(:extent) object"}},

      "external_ids" => {"type" => "array", "items" => {"type" => "JSONModel(:external_id) object"}},

      "file_issue_allowed" => {"type" => "boolean", "default" => true},

      "format" => {"type" => "string", "dynamic_enum" => "runcorn_format", "ifmissing" => "error"},

      "intended_use" => {"type" => "string", "dynamic_enum" => "runcorn_intended_use"},

      "original_registration_date" => {"type" => "string"},

      "other_restrictions_notes" => {"type" => "string"},

      "physical_description_type" => {"type" => "string", "dynamic_enum" => "runcorn_physical_description_type"},

      "publish" => {"type" => "boolean"},

      "preferred_citation" => {"type" => "string"},

      "preservation_notes" => {"type" => "string"},

      "preservation_restriction_status" => {"type" => "string", "dynamic_enum" => "runcorn_physical_preservation_restriction_status", "ifmissing" => "error"},

      "remark" => {"type" => "string"},

      "salvage_priority_code" => {"type" => "string", "dynamic_enum" => "runcorn_salvage_priority_code"},

      "sterilised_status" => {"type" => "boolean"},

      "title" => {"type" => "string"},
    },
  },
}
