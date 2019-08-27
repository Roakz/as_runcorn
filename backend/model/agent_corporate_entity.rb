AgentCorporateEntity.prepend(ManagedRegistration)
AgentCorporateEntity.include(ExternalIDs)
AgentCorporateEntity.include(AgencyDeletionRules)
AgentCorporateEntity.include(ExternalReferences)

class AgentCorporateEntity
  def validate
    if self.publish == 1 && self.registration_state != 'approved'
      errors.add(:publish, "Unable to publish when in draft")
    end
  end
end