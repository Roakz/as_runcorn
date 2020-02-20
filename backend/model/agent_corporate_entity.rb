AgentCorporateEntity.prepend(ManagedRegistration)
AgentCorporateEntity.include(ExternalIDs)
AgentCorporateEntity.include(AgencyDeletionRules)
AgentCorporateEntity.include(Batchable)

class AgentCorporateEntity

  alias_method :as_runcorn_validate_orig, :validate
  def validate
    as_runcorn_validate_orig

    if self.publish == 1 && self.registration_state != 'approved'
      errors.add(:publish, "Unable to publish when in draft")
    end
  end
end