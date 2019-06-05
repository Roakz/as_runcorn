require_relative '../common/managed_registration_init'
require_relative '../common/validations'
require_relative '../common/qsa_id'
require_relative '../common/qsa_id_registrations'

Permission.define("manage_agency_registration",
                  "The ability to manage the agency registration workflow",
                  :level => "repository")

Permission.define("approve_agency_registration",
                  "The ability to approve the registration of a draft agency",
                  :implied_by => "manage_agency_registration",
                  :level => "global")

begin
  History.register_model(ChargeableItem)
  History.register_model(ChargeableService)
rescue NameError
  Log.info("Unable to register ChargeableItem and ChargeableService for history. Please install the as_history plugin")
end

require_relative 'lib/file_storage'
require_relative 'lib/s3_storage'
require_relative 'lib/byte_storage'

# Config test!
ByteStorage.get
