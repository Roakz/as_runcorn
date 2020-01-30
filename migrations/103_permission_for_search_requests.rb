require 'db/migrations/utils'

Sequel.migration do

  up do
    now = Time.now

    new_perms = [
                   {
                     :code => 'manage_search_requests',
                     :description => 'The ability to manage search requests',
                     :groups => ['repository-senior-archivists', 'repository-collection-managers',
                                 'repository-transfer-file-issue']
                   },
                 ]

    admin_group_id = self[:group].filter(:group_code => 'administrators').get(:id)

    unless admin_group_id.nil?
      new_perms.each do |perm|
        perm_id = self[:permission].insert(
          :permission_code => perm[:code],
          :description => perm[:description],
          :level => 'repository',
          :system => 0,
          :create_time => now,
          :system_mtime => now,
          :user_mtime => now
        )

        self[:group_permission].insert(:permission_id => perm_id, :group_id => admin_group_id)

        self[:repository].where{id > 1}.each do |repo|
          repo_id = repo[:id]

          perm[:groups].each do |group_code|
            group_id = self[:group].filter(:repo_id => repo_id, :group_code => group_code).get(:id)

            self[:group_permission].insert(:permission_id => perm_id, :group_id => group_id)
          end
        end
      end
    end
  end
end
