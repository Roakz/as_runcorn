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
require_relative 'lib/s3_authenticated_storage'
require_relative 'lib/byte_storage'

# FIXME: delete this post-release
# If rap_applied doesn't have series set, regenerate.
DB.open do |db|
  if db[:rap_applied].filter(:root_record_id => nil).count > 0
    db[:rap_applied].delete
    [2, 3].each do |repo_id|
      RequestContext.open(:repo_id => repo_id) do
        Resource.each do |resource|
          resource.propagate_raps!
        end
      end
    end
  end
end

# Config test!
ByteStorage.get

# TreeReordering.add_after_reorder_hook do |target_class, child_class, target_id, child_ids, position|
#   if child_class == ArchivalObject
#     resource = if target_class == Resource
#                  Resource.get_or_die(target_id)
#                else
#                  ao = ArchivalObject.get_or_die(target_id)
#                  Resource.get_or_die(ao.root_record_id)
#                end
# 
#     resource.propagate_raps!
#   end
# end

# Make sure the default RAP exists from the outset

# DB.attempt {
#   RAP.get_default_id
# }.and_if_constraint_fails do |e|
#   Log.warn("Constraint failure while creating default RAP: #{e}")
# end

#require_relative 'lib/rap_provisioner'
#RapProvisioner.doit!
