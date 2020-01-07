require 'db/migrations/utils'

Sequel.migration do

  up do
    new_groups = [
                  {
                    :copy_from => 'repository-project-managers',
                    :code => 'repository-collection-archivists',
                    :description => 'Collection Archivists',
                  },
                  {
                    :copy_from => false,
                    :code => 'repository-archivists-other',
                    :description => 'Archivists - Other',
                  },
                  {
                    :copy_from => false,
                    :code => 'reading-room-staff',
                    :description => 'Reading room staff',
                  },
                 ]

    # applying these groups to all repos, ie repo_id > 1

    now = Time.now

    self[:repository].where{id > 1}.each do |repo|
      repo_id = repo[:id]
      repo_code = repo[:repo_code]

      new_groups.each do |group|
        new_id = self[:group].insert(
                                     :json_schema_version => 1,
                                     :repo_id => repo_id,
                                     :group_code => group[:code],
                                     :group_code_norm => group[:code].downcase,
                                     :description => "%s of the %s repository" % [group[:description], repo_code],
                                     :create_time => now,
                                     :system_mtime => now,
                                     :user_mtime => now)

        if group[:copy_from]
          old_id = self[:group].filter(:repo_id => repo_id, :group_code => group[:copy_from]).get(:id)

          self[:group_permission].filter(:group_id => old_id).each do |gp|
            self[:group_permission].insert(:group_id => new_id, :permission_id => gp[:permission_id])
          end

          self[:group_user].filter(:group_id => old_id).each do |gu|
            self[:group_user].insert(:group_id => new_id, :user_id => gu[:user_id])
          end
        end
      end
    end
  end

end
