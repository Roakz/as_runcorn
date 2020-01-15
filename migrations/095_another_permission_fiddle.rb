require 'db/migrations/utils'

Sequel.migration do

  up do

    # delete approve_closed_records and group refs - it's now an implied global
    perm_id = self[:permission].filter(:permission_code => 'approve_closed_records').get(:id)
    self[:group_permission].filter(:permission_id => perm_id).delete
    self[:permission].filter(:id => perm_id).delete

    # create manage_closed_record_approval with groups
    new_perms = [
                 {
                   :code => 'manage_closed_record_approval',
                   :description => 'The ability to manage agency approval of closed records',
                   :groups => ['repository-senior-archivists', 'repository-collection-managers',
                               'repository-collection-archivists', 'repository-archivists-other',
                               'repository-reading-room-staff']
                 },
                ]

    now = Time.now

    admin_group_id = self[:group].filter(:group_code => 'administrators').get(:id)

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
