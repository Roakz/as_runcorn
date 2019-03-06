require_relative '../common/managed_registration_init'

Permission.define("manage_agency_registration",
                  "The ability to manage the agency registration workflow",
                  :level => "repository")

Permission.define("approve_agency_registration",
                  "The ability to approve the registration of a draft agency",
                  :implied_by => "manage_agency_registration",
                  :level => "global")

[
 Resource,
 ArchivalObject,
 DigitalObject,
 Function,
 Mandate,
 Accession,
 AgentCorporateEntity,
].each do |model|
  model.instance_eval do
    self.include(AutoGenerator)

    self.auto_generate :property => :qsa_id,
                       :generator => proc { |json| Sequence.get("QSA_ID_#{model.table_name.upcase}") },
                       :only_on_create => true

    model.my_jsonmodel.schema['properties']['qsa_id'] = {
      "type" => "integer",
      "readonly" => true
    }
  end
end
