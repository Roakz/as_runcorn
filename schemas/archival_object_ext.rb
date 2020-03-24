{
  "description" => {"type" => "string"},
  "access_clearance_procedure" => {"type" => "string", "dynamic_enum" => "runcorn_access_clearance_procedure"},
  "disposal_class" => {"type" => "string"},
  "sensitivity_label" => {"type" => "string", "dynamic_enum" => "runcorn_sensitivity_label"},
  "significance" => {"type" => "string", "dynamic_enum" => "runcorn_significance", "default" => "standard"},
  "significance_is_sticky" => {"type" => "boolean", "default" => false},

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

  "physical_representations" => {
    "type" => "array",
    "items" => {"type" => "JSONModel(:physical_representation) object"}
  },
  "digital_representations" => {
    "type" => "array",
    "items" => {"type" => "JSONModel(:digital_representation) object"}
  },

  "physical_representations_count" => {"type"=> "number", "readonly" => "true"},
  "digital_representations_count" => {"type"=> "number", "readonly" => "true"},

  "transfer_id" => {"type"=> "number"},
  "transfer_qsa_id" => {"type"=> "string", "readonly" => "true"},
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

  "deaccessions" => {"type" => "array", "items" => {"type" => "JSONModel(:deaccession) object"}},
  "deaccessioned" => {"type" => "boolean", "readonly" => "true"},

  "agency_assigned_id" => {"type" => "string"},

  "rap_attached" => {"type" => "JSONModel(:rap) object"},

  "rap_applied" => {
    "type" => "JSONModel(:rap) object",
    "readonly" => "true",
  },

  "rap_access_status" => {
    "type" => "string",
    "readonly" => "true",
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

  "publishable" => {
    "type" => "boolean",
    "readonly" => "true"
  },

  "archivist_approved" => {"type" => "boolean"},
  "copyright_status" => {"type" => "string", "dynamic_enum" => "runcorn_copyright_status"},
  "original_registration_date" => {"type" => "string"},
  "previous_system_identifiers" => {"type" => "string"},
  "accessioned_status" => {"type" => "string", "dynamic_enum" => "runcorn_accessioned_status"},

  "within" => {
    "type" => "array",
    "readonly" => "true",
    "items" => {
      "type" => "string",
    }
  },

  "series_retention_status" => {
    "type" => "string",
    "readonly" => "true"
  },

  "series_summary" => {
    "type" => "object",
    "subtype" => "ref",
    "readonly" => "true",
    "properties" => {
      "qsa_id" => {"type" => "number"},
      "qsa_id_prefixed" => {"type" => "string"},
      "title" => {"type" => "string"},
    }
  },
}
