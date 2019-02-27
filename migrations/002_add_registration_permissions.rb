require 'db/migrations/utils'

Sequel.migration do

  up do
    perm = self[:permission].filter(:permission_code => 'manage_agency_registration').first

    perm_id = if perm.nil?
                self[:permission].insert(:permission_code => 'manage_agency_registration',
                                         :description => 'The ability to manage the agency registration workflow',
                                         :create_time => Time.now,
                                         :system_mtime => Time.now,
                                         :user_mtime => Time.now)
              else
                perm[:id]
              end

    self[:group].filter(:group_code => 'repository-managers').each do |group|
      begin
        self[:group_permission].insert(:permission_id => perm_id,
                                       :group_id => group[:id])
      rescue Sequel::UniqueConstraintViolation
        # no worries, it's already there
      end
    end
  end

  down do
  end
end
