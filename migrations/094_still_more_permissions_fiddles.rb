require 'db/migrations/utils'

Sequel.migration do

  up do
    now = Time.now

    self[:permission].filter(:permission_code => 'update_resource_record')
      .update(:description => 'The ability to create and modify series, item and representation records',
              :system_mtime => now)

    existing_perms = [
                      {
                        :code => 'update_resource_record',
                        :groups => ['repository-senior-archivists', 'repository-collection-managers',
                                    'repository-collection-archivists', 'repository-archivists-other',
                                    'repository-transfer-file-issue', 'repository-preservation-team']
                      },
                     ]

    repo_group_ids = self[:group].where{repo_id > 1}.select(:id).map{|g| g[:id]}

    existing_perms.each do |perm|
      perm_id = self[:permission].filter(:permission_code => perm[:code]).get(:id)

      self[:group_permission].filter(:permission_id => perm_id).filter(:group_id => repo_group_ids).delete

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
