include FactoryBotSyntaxHelpers

# Override json_date now that 'approximate' is the only valid option
FactoryBot.modify do
  factory :json_date, class: JSONModel(:date) do
    date_type { generate(:date_type) }
    label 'creation'
    self.begin { generate(:yyyy_mm_dd) }
    self.end { self.begin }
    self.certainty 'approximate'
    self.era 'ce'
    self.calendar 'gregorian'
    expression { generate(:alphanumstr) }
  end

  factory :json_date_single, class: JSONModel(:date) do
    date_type 'single'
    label 'creation'
    self.begin { generate(:yyyy_mm_dd) }
    self.certainty 'approximate'
    self.era 'ce'
    self.calendar 'gregorian'
    expression { generate(:alphanumstr) }
  end
end