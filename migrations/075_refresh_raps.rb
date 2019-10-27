require 'db/migrations/utils'

Sequel.migration do

  up do
    # Clear rap_applied so we populate resource_id in UAT.  We'll regenerate these on startup anyway.
    self[:rap_applied].delete
  end

end
