{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "version" => 1,
    "type" => "object",
    "uri" => "/repositories/:repo_id/digital_representations",
    "properties" => {
      "uri" => {"type" => "string"},

      "existing_ref" => { "type" => "JSONModel(:digital_representation) uri"},
      "display_string" => {"type" => "string", "maxLength" => 8192, "readonly" => true},

      "access_category" => {"type" => "string", "dynamic_enum" => "runcorn_access_category"},

      "normal_location" => {"type" => "string", "dynamic_enum" => "runcorn_location", "ifmissing" => "error"},

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

      "contained_within" => {"type" => "string", "dynamic_enum" => "runcorn_digital_representation_contained_within", "ifmissing" => "error"},

      "deaccessions" => {"type" => "array", "items" => {"type" => "JSONModel(:deaccession) object"}},

      "description" => {"type" => "string"},

      "exhibition_history" => {"type" => "string"},

      "exhibition_notes" => {"type" => "string"},

      "exhibition_quality" => {"type" => "boolean"},

      "external_ids" => {"type" => "array", "items" => {"type" => "JSONModel(:external_id) object"}},

      "file_issue_allowed" => {"type" => "boolean", "default" => true},

      "file_size" => {"type" => "string"},

      "file_type" => {"type" => "string", "dynamic_enum" => "runcorn_digital_file_type", "ifmissing" => "error"},

      "intended_use" => {"type" => "string", "dynamic_enum" => "runcorn_intended_use"},

      "original_registration_date" => {"type" => "string"},

      "other_restrictions_notes" => {"type" => "string"},

      "publish" => {"type" => "boolean"},

      "preferred_citation" => {"type" => "string"},

      "preservation_notes" => {"type" => "string"},

      "preservation_priority_rating" => {"type" => "string", "dynamic_enum" => "runcorn_preservation_priority_rating"},

      "processing_handling_notes" => {"type" => "string"},

      "remarks" => {"type" => "string"},

      "salvage_priority_code" => {"type" => "string", "dynamic_enum" => "runcorn_salvage_priority_code"},

      "title" => {"type" => "string", "ifmissing" => "error"},

      "controlling_record" => {
        "type" => "object",
        "subtype" => "ref",
        "properties" => {
          "ref" => {"type" => [{"type" => "JSONModel(:archival_object) uri"}],
                    "ifmissing" => "error"},
          "_resolved" => {
            "type" => "object",
            "readonly" => "true"
          }
        }
      },

      "related_accession" => {
        "type" => "object",
        "subtype" => "ref",
        "properties" => {
          "ref" => {"type" => [{"type" => "JSONModel(:accession) uri"}],
                    "ifmissing" => "error"},
          "_resolved" => {
            "type" => "object",
            "readonly" => "true"
          }
        }
      },

      "responsible_agency" => {
        "type" => "object",
        "subtype" => "ref",
        "properties" => {
          "ref" => {
            "type" => [{"type" => "JSONModel(:agent_corporate_entity) uri"}],
            "readonly" => "true"
          },
          "_resolved" => {
            "type" => "object",
            "readonly" => "true"
          }
        }
      },
      "recent_responsible_agencies" => {
        "type" => "array",
        "items" => {
          "type" => "object",
          "subtype" => "ref",
          "properties" => {
            "ref" => {
              "type" => [{"type" => "JSONModel(:agent_corporate_entity) uri"}],
              "readonly" => "true"
            },
            "end_date" => {
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

      "representation_file" => {"type" => "JSONModel(:representation_file) object"},
    },
  },
}
