{
  "current_location" => {"type" => "string", "dynamic_enum" => "runcorn_location", "ifmissing" => "error"},
  "movements" => {"type" => "array", "items" => {"type" => "JSONModel(:movement) object"}},
}