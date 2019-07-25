FactoryBot.modify do
  # Override json_date now that 'approximate' is the only valid option
  factory :json_date, class: JSONModel::JSONModel(:date) do
    self.certainty { 'approximate' }
  end
  factory :json_date_single, class: JSONModel::JSONModel(:date) do
    self.certainty { 'approximate' }
  end
  factory :json_top_container, class: JSONModel::JSONModel(:top_container) do
    self.current_location { 'HOME' }
  end
end


FactoryBot.define do
  sequence(:runcorn_location) { sample(JSONModel::JSONModel(:physical_representation).schema['properties']['current_location']) }
  sequence(:runcorn_format) { sample(JSONModel::JSONModel(:physical_representation).schema['properties']['format']) }
  sequence(:runcorn_physical_representation_contained_within) { sample(JSONModel::JSONModel(:physical_representation).schema['properties']['contained_within']) }
  sequence(:runcorn_digital_representation_contained_within) { sample(JSONModel::JSONModel(:digital_representation).schema['properties']['contained_within']) }
  sequence(:runcorn_file_type) { sample(JSONModel::JSONModel(:digital_representation).schema['properties']['file_type']) }

  sequence(:runcorn_charge_quantity_unit) { sample(JSONModel::JSONModel(:chargeable_item).schema['properties']['charge_quantity_unit']) }
  sequence(:runcorn_price_cents) { rand(10000) + 99 }
  sequence(:runcorn_quote_line_quantity) { rand(100) }
  sequence(:runcorn_unique_name) { SecureRandom.hex }

  factory :json_digital_representation, class: JSONModel::JSONModel(:digital_representation) do
    uri { generate(:url) }
    title { generate(:generic_title) }
    description { generate(:generic_description) }
    normal_location { generate(:runcorn_location) }
    file_type { generate(:runcorn_file_type) }
    contained_within { generate(:runcorn_digital_representation_contained_within) }
  end

  factory :json_physical_representation, class: JSONModel::JSONModel(:physical_representation) do
    uri { generate(:url) }
    title { generate(:generic_title) }
    description { generate(:generic_description) }
    current_location { generate(:runcorn_location) }
    normal_location { generate(:runcorn_location) }
    format { generate(:runcorn_format) }
    contained_within { generate(:runcorn_physical_representation_contained_within) }
    container { {:ref => create(:json_top_container).uri} }
  end

  factory :json_chargeable_item, class: JSONModel::JSONModel(:chargeable_item) do
    uri { generate(:url) }
    name { generate(:runcorn_unique_name) }
    description { generate(:generic_description) }
    price_cents { generate(:runcorn_price_cents) }
    charge_quantity_unit { generate(:runcorn_charge_quantity_unit) }
  end

  factory :json_chargeable_service, class: JSONModel::JSONModel(:chargeable_service) do
    uri { generate(:url) }
    name { generate(:generic_title) }
    description { generate(:generic_description) }
    service_items { [{'ref' => create(:json_chargeable_item).uri}] }
  end

  factory :json_service_quote, class: JSONModel::JSONModel(:service_quote) do
    uri { generate(:url) }
    chargeable_service { {'ref' => create(:json_chargeable_service).uri} }
    line_items { [build(:json_service_quote_line)] }
  end

  factory :json_service_quote_line, class: JSONModel::JSONModel(:service_quote_line) do
    chargeable_item { {'ref' => create(:json_chargeable_item).uri} }
    quantity { generate(:runcorn_quote_line_quantity) }
  end

  factory :json_conservation_request, class: JSONModel::JSONModel(:conservation_request) do
    date_of_request { Date.today.iso8601 }
    date_required_by { (Date.today + 30).iso8601 }
    requested_by { "conservation_request_user" }
    reason_requested { "nefarious schemes" }
    reason_requested_comments { "have a nice day" }
  end

end
