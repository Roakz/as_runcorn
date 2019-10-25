{
  "external_ids" => {"type" => "array", "items" => {"type" => "JSONModel(:external_id) object"}},
  "original_registration_date" => {"type" => "string"},
  "notes" => {
      "type" => "array",
      "items" => {"type" => [{"type" => "JSONModel(:note_singlepart) object"}]}
  }
}
