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
  }
}
