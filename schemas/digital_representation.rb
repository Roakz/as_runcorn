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

      "deaccessioned" => {"type" => "boolean", "readonly" => "true"},

      "description" => {"type" => "string"},

      "exhibition_history" => {"type" => "string"},

      "exhibition_notes" => {"type" => "string"},

      "exhibition_quality" => {"type" => "boolean"},

      "external_ids" => {"type" => "array", "items" => {"type" => "JSONModel(:external_id) object"}},

      "file_issue_allowed" => {"type" => "string", "dynamic_enum" => "runcorn_file_issue_allowed", "default" => "allowed_true"},

      "file_size" => {"type" => "string"},

      "file_type" => {"type" => "string", "dynamic_enum" => "runcorn_digital_file_type"},

      "intended_use" => {"type" => "string", "dynamic_enum" => "runcorn_intended_use"},

      "original_registration_date" => {"type" => "string"},

      "other_restrictions_notes" => {"type" => "string"},

      "publish" => {"type" => "boolean"},
      "has_unpublished_ancestor" => {"type" => "boolean", "readonly" => "true"},

      "preferred_citation" => {"type" => "string"},

      "preservation_notes" => {"type" => "string"},

      "preservation_priority_rating" => {"type" => "string", "dynamic_enum" => "runcorn_preservation_priority_rating"},

      "processing_handling_notes" => {"type" => "string"},

      "remarks" => {"type" => "string"},

      "significance" => {"type" => "string", "dynamic_enum" => "runcorn_significance"},

      "title" => {"type" => "string", "ifmissing" => "error"},

      "controlling_record" => {
        "type" => "object",
        "subtype" => "ref",
        "properties" => {
          "ref" => {"type" => [{"type" => "JSONModel(:archival_object) uri"}],
                    "ifmissing" => "error"},
          "qsa_id" => {"type" => "number", "readonly" => "true"},
          "qsa_id_prefixed" => {"type" => "string", "readonly" => "true"},
          "title" => {"type" => "string", "readonly" => "true"},
          "begin_date" => {"type" => "string", "readonly" => "true"},
          "end_date" => {"type" => "string", "readonly" => "true"},
          "_resolved" => {
            "type" => "object",
            "readonly" => "true"
          }
        }
      },

      "controlling_record_series" => {
        "type" => "object",
        "subtype" => "ref",
        "readonly" => "true",
        "properties" => {
          "ref" => {"type" => [{"type" => "JSONModel(:resource) uri"}],
                    "ifmissing" => "error"},
          "qsa_id" => {"type" => "number"},
          "qsa_id_prefixed" => {"type" => "string"},
          "title" => {"type" => "string"},
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
          "start_date" => {
            "type" => "string",
            "readonly" => "true"
          },
          "inherited" => {
            "type" => "boolean",
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

      "rap_attached" => {"type" => "JSONModel(:rap) object"},

      "rap_applied" => {
        "type" => "JSONModel(:rap) object",
        "readonly" => "true",
      },

      "rap_access_status" => {
        "type" => "string",
        "readonly" => "true",
      },

      "rap_expiration" => {
        "type" => "object",
        "readonly" => "true",
        "properties" => {
          "existence_end_date" => {"type" => "date"},
          "expiry_date" => {"type" => "date"},
          "expired" => {"type" => "boolean"},
          "expires" => {"type" => "boolean"},
        },
      },

      "rap_history" => {
        "readonly" => "true",
        "type" => "array",
        "items" => {
          "type" => "object",
          "subtype" => "ref",
          "properties" => {
            "ref" => {
              "type" => [{"type" => "JSONModel(:rap) uri"}],
              "ifmissing" => "error",
            },
            "is_active" => {"type" => "boolean"},
            "_resolved" => {
              "type" => "object",
            },
          },
        }
      },

      "publishable" => {
        "type" => "boolean",
        "readonly" => "true"
      },

      "archivist_approved" => {"type" => "boolean"},

      "within" => {
        "type" => "array",
        "readonly" => "true",
        "items" => {
          "type" => "string",
        }
      },

      "transfer_qsa_id" => {"type"=> "string", "readonly" => "true"},
      "transfer_id" => {"type"=> "number"},
      "transfer" => {
          "type" => "object",
          "subtype" => "ref",
          "properties" => {
              "ref" => {
                  "type" => [{"type" => "JSONModel(:transfer) uri"}],
                  "ifmissing" => "error"
              },
              "_resolved" => {
                  "type" => "object",
                  "readonly" => "true"
              }
          }
      },
      "previous_system_identifiers" => {"type" => "string"},
      "image_resource_type" => {"type" => "string", "dynamic_enum" => "runcorn_image_resource_type"},

      "series_retention_status" => {
        "type" => "string",
        "readonly" => "true"
      },

      "frequency_of_use" => {
        "type" => "non_negative_integer",
        "readonly" => "true",
      },
    },
  }
}
