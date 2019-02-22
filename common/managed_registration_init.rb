module JSONModel
  module Validations
    def self.check_draft_publish(hash)
      errors = []
      if hash['publish'] && hash['registration_state'] != 'approved'
        errors << ['publish', 'Unable to publish when in draft']
      end
      errors
    end

    if JSONModel(:agent_corporate_entity)
      JSONModel(:agent_corporate_entity).add_validation("check_agency_draft_publish") do |hash|
        check_draft_publish(hash)
      end
    end

  end
end
