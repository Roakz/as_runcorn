{
  "registration_state" => {
    "type" => "string",
    "enum" => ["draft", "submitted", "approved"],
    "readonly" => true
  },
  "registration_last_action" => {
    "type" => "string",
    "readonly" => true
  },
  "registration_last_user" => {
    "type" => "string",
    "readonly" => true
  },
  "registration_last_time" => {
    "type" => "date-time",
    "readonly" => true
  },
  "agency_note" => {
    "type" => "string",
  },
  "agency_category" => {
    "type" => "string",
    "dynamic_enum" => "agency_category",
  },
  "external_resources" => {
    "type" => "array",
    "items" => {
      "type" => "JSONModel(:external_resource) object"
    }
  }
}
