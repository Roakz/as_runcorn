require_relative '../common/managed_registration_init'

Permission.define("manage_agency_registration",
                  "The ability to manage the agency registration workflow",
                  :level => "repository")

Permission.define("approve_agency_registration",
                  "The ability to approve the registration of a draft agency",
                  :implied_by => "manage_agency_registration",
                  :level => "global")

QSAId.register(Resource, :id_0)
QSAId.register(ArchivalObject, :ref_id)
QSAId.register(DigitalObject, :digital_object_id)
QSAId.register(Function)
QSAId.register(Mandate)
QSAId.register(Accession, :id_0)
QSAId.register(AgentCorporateEntity)
