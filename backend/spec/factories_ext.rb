FactoryBot.modify do
  # Override json_date now that 'approximate' is the only valid option
  factory :json_date, class: JSONModel::JSONModel(:date) do
    self.certainty 'approximate'
  end
  factory :json_date_single, class: JSONModel::JSONModel(:date) do
    self.certainty 'approximate'
  end
end


FactoryBot.define do
  sequence(:runcorn_location) { sample(JSONModel::JSONModel(:physical_representation).schema['properties']['current_location']) }
  sequence(:runcorn_format) { sample(JSONModel::JSONModel(:physical_representation).schema['properties']['format']) }
  sequence(:runcorn_physical_representation_contained_within) { sample(JSONModel::JSONModel(:physical_representation).schema['properties']['contained_within']) }
  sequence(:runcorn_digital_representation_contained_within) { sample(JSONModel::JSONModel(:digital_representation).schema['properties']['contained_within']) }
  sequence(:runcorn_file_type) { sample(JSONModel::JSONModel(:digital_representation).schema['properties']['file_type']) }

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
  end
end
