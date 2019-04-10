require_relative '../common/managed_registration_init'
require_relative '../common/validation_overrides'
require_relative '../common/qsa_id'
require_relative '../common/qsa_id_registrations'

Permission.define("manage_agency_registration",
                  "The ability to manage the agency registration workflow",
                  :level => "repository")

Permission.define("approve_agency_registration",
                  "The ability to approve the registration of a draft agency",
                  :implied_by => "manage_agency_registration",
                  :level => "global")
