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
                    :code => 'repository-reading-room-staff',
                    :description => 'Reading room staff',
                  },
                  {
                    :copy_from => 'repository-managers',
                    :code => 'repository-preservation-team',
                    :description => 'Preservation Team',
                  },
                 ]

    modified_groups = {
      'repository-managers' => {
        :code => 'repository-senior-archivists',
        :description => 'Senior Archivists'
      },
      'repository-project-managers' => {
        :code => 'repository-collection-managers',
        :description => 'Managers of Collection Enrichment and Discovery'
      },
      'repository-advanced-data-entry' => {
        :code => 'repository-transfer-file-issue',
        :description => 'Repository/ transfer/file issue'
      },
      'repository-basic-data-entry' => {
        :code => 'repository-data-entry-volunteers',
        :description => 'Data Entry/ Volunteers'
      },
      'repository-archivists' => {
        :code => 'repository-archivists-other',
        :description => 'Archivists - Other'
      },
    }

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

      modified_groups.each do |old_code, group|
        self[:group]
          .filter(:repo_id => repo_id, :group_code_norm => old_code)
          .update(
                  :group_code => group[:code],
                  :group_code_norm => group[:code].downcase,
                  :description => "%s of the %s repository" % [group[:description], repo_code],
                  :system_mtime => now
                  )
      end

    end
  end

end
