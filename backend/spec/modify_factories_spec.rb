include FactoryBotSyntaxHelpers

# Override json_date now that 'approximate' is the only valid option
FactoryBot.modify do
  factory :json_date, class: JSONModel(:date) do
    self.certainty 'approximate'
  end

  factory :json_date_single, class: JSONModel(:date) do
    self.certainty 'approximate'
  end
end