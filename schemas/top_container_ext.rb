{
  "current_location" => {"type" => "string", "dynamic_enum" => "runcorn_location", "default" => "HOME"},
  "movements" => {"type" => "array", "items" => {"type" => "JSONModel(:movement) object"}},
  "move_to_storage_permitted" => {"type" => "boolean", "readonly" => "true"},
}
