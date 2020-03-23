{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "version" => 1,
    "type" => "object",
    "uri" => "/repositories/:repo_id/physical_representations",
    "properties" => {
      "uri" => {"type" => "string"},

      "existing_ref" => { "type" => "JSONModel(:physical_representation) uri"},
      "display_string" => {"type" => "string", "maxLength" => 8192, "readonly" => true},

      "current_location" => {"type" => "string", "dynamic_enum" => "runcorn_location", "ifmissing" => "error"},

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

      "contained_within" => {"type" => "string", "dynamic_enum" => "runcorn_physical_representation_contained_within", "ifmissing" => "error"},

      "container" => {
        "type" => "object",
        "subtype" => "ref",
        "properties" => {
          "ref" => {"type" => "JSONModel(:top_container) uri",
                    "ifmissing" => "error"},
          "_resolved" => {
            "type" => "object",
            "readonly" => "true",
          }
        }
      },

      "deaccessions" => {"type" => "array", "items" => {"type" => "JSONModel(:deaccession) object"}},

      "deaccessioned" => {"type" => "boolean"},

      "description" => {"type" => "string"},

      "exhibition_history" => {"type" => "string"},

      "exhibition_notes" => {"type" => "string"},

      "exhibition_quality" => {"type" => "boolean"},

      "extents" => {"type" => "array", "items" => {"type" => "JSONModel(:extent) object"}},

      "external_ids" => {"type" => "array", "items" => {"type" => "JSONModel(:external_id) object"}},

      "file_issue_allowed" => {"type" => "string", "dynamic_enum" => "runcorn_file_issue_allowed", "default" => "allowed_true"},

      "format" => {"type" => "string", "dynamic_enum" => "runcorn_format", "ifmissing" => "error"},

      "intended_use" => {"type" => "string", "dynamic_enum" => "runcorn_intended_use"},

      "original_registration_date" => {"type" => "string"},

      "other_restrictions_notes" => {"type" => "string"},

      "physical_format_details" => {"type" => "string"},

      "publish" => {"type" => "boolean"},
      "has_unpublished_ancestor" => {"type" => "boolean", "readonly" => "true"},

      "preferred_citation" => {"type" => "string"},

      "preservation_notes" => {"type" => "string"},

      "preservation_priority_rating" => {"type" => "string", "dynamic_enum" => "runcorn_preservation_priority_rating"},

      "processing_handling_notes" => {"type" => "string"},

      "remarks" => {"type" => "string"},

      "significance" => {"type" => "string", "dynamic_enum" => "runcorn_significance", "default" => "standard"},
      "significance_is_sticky" => {"type" => "boolean", "default" => false},

      "sterilised_status" => {"type" => "boolean"},

      "title" => {"type" => "string", "ifmissing" => "error"},

      "monetary_value" => {"type" => "string"},
      "monetary_value_note" => {"type" => "string"},

      "controlling_record" => {
        "type" => "object",
        "subtype" => "ref",
        "readonly" => "true",
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
        "readonly" => "true",
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
        "readonly" => "true",
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

      "movements" => {"type" => "array", "items" => {"type" => "JSONModel(:movement) object"}},
      "move_to_storage_permitted" => {"type" => "boolean", "readonly" => "true"},

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

      "conservation_requests" => {
        "readonly" => "true",
        "type" => "array",
        "items" => {
          "type" => "object",
          "subtype" => "ref",
          "properties" => {
            "ref" => {
              "type" => [{"type" => "JSONModel(:conservation_request) uri"}],
              "readonly" => "true"
            },
            "status" => {
              "type" => "string",
              "readonly" => "true",
            },
            "_resolved" => {
              "type" => "object",
              "readonly" => "true"
            }
          }
        }
      },

      "conservation_treatments" => {
        "type" => "array",
        "items" => {
          "type" => "JSONModel(:conservation_treatment) object",
        },
      },

      "frequency_of_use" => {
        "type" => "non_negative_integer",
        "readonly" => "true",
      },

      "assessments" => {
        "readonly" => "true",
        "type" => "array",
        "items" => {
          "type" => "object",
          "subtype" => "ref",
          "properties" => {
            "ref" => {
              "type" => [{"type" => "JSONModel(:assessment) uri"}],
              "readonly" => "true"
            },
            "_resolved" => {
              "type" => "object",
              "readonly" => "true"
            }
          },
        },
      },

      "availability" => {"type" => "string", "dynamic_enum" => "runcorn_physical_representation_availability"},
      "calculated_availability" => {
        "type" => "string",
        "readonly" => "true",
      },
      "calculated_availability_overrides_availability" => {
        "type" => "boolean",
        "readonly" => "true",
      },


      "publishable" => {
        "type" => "boolean",
        "readonly" => "true"
      },

      "archivist_approved" => {"type" => "boolean"},
      "container_profile" => {"type" => "string"},
      "container_type" => {"type" => "string"},
      "indicator" => {"type" => "string"},
      "barcode" => {"type" => "string"},
      "previous_system_identifiers" => {"type" => "string"},

      "within" => {
        "type" => "array",
        "readonly" => "true",
        "items" => {
          "type" => "string",
        }
      },

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

      "series_retention_status" => {
        "type" => "string",
        "readonly" => "true"
      },
    },
  },
}
