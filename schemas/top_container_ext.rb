{
  "current_location" => {"type" => "string", "dynamic_enum" => "runcorn_location", "default" => "HOME"},
  "movements" => {"type" => "array", "items" => {"type" => "JSONModel(:movement) object"}},
}
