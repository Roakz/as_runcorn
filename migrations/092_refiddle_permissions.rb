require 'db/migrations/utils'

Sequel.migration do

  up do
    existing_perms = [
                      {
                        :code => 'manage_enumeration_record',
                        :groups => []
                      },
                      {
                        :code => 'transfer_repository',
                        :groups => ['repository-senior-archivists', 'repository-collection-managers']
                      },
                      {
                        :code => 'mog_update',
                        :groups => ['repository-senior-archivists', 'repository-collection-managers']
                      },
                      {
                        :code => 'manage_agency_registration',
                        :groups => ['repository-senior-archivists', 'repository-collection-managers']
                      },
                      {
                        :code => 'update_resource_record',
                        :groups => ['repository-senior-archivists', 'repository-collection-managers']
                      },
                      {
                        :code => 'manage_repository',
                        :groups => ['repository-senior-archivists', 'repository-collection-managers']
                      },
                      {
                        :code => 'manage_function_record',
                        :groups => ['repository-senior-archivists', 'repository-collection-managers']
                      },
                      {
                        :code => 'manage_mandate_record',
                        :groups => ['repository-senior-archivists', 'repository-collection-managers']
                      },
                      {
                        :code => 'update_digital_object_record',
                        :groups => ['repository-senior-archivists', 'repository-collection-managers',
                                    'repository-collection-archivists', 'repository-archivists-other',
                                    'repository-transfer-file-issue', 'repository-preservation-team']
                      },
                      {
                        :code => 'transfer_archival_record',
                        :groups => ['repository-senior-archivists', 'repository-collection-managers',
                                    'repository-collection-archivists', 'repository-archivists-other',
                                    'repository-preservation-team']
                      },
                      {
                        :code => 'delete_archival_record',
                        :groups => ['repository-senior-archivists', 'repository-collection-managers']
                      },
                      {
                        :code => 'view_repository',
                        :groups => ['repository-senior-archivists', 'repository-collection-managers',
                                    'repository-collection-archivists', 'repository-archivists-other',
                                    'repository-transfer-file-issue', 'repository-data-entry-volunteers',
                                    'repository-reading-room-staff', 'repository-viewers',
                                    'repository-preservation-team']
                      },
                      {
                        :code => 'import_records',
                        :groups => ['repository-senior-archivists', 'repository-collection-managers',
                                    'repository-collection-archivists', 'repository-transfer-file-issue']
                      },
                      {
                        :code => 'cancel_importer_job',
                        :groups => ['repository-senior-archivists', 'repository-collection-managers',
                                    'repository-collection-archivists', 'repository-transfer-file-issue']
                      },
                      {
                        :code => 'manage_subject_record',
                        :groups => ['repository-senior-archivists', 'repository-collection-managers',
                                    'repository-collection-archivists', 'repository-archivists-other',
                                    'repository-transfer-file-issue', 'repository-preservation-team']
                      },
                      {
                        :code => 'manage_agent_record',
                        :groups => ['repository-senior-archivists', 'repository-collection-managers',
                                    'repository-collection-archivists']
                      },
                      {
                        :code => 'manage_vocabulary_record',
                        :groups => ['repository-senior-archivists', 'repository-collection-managers']
                      },
                      {
                        :code => 'merge_agents_and_subjects',
                        :groups => ['repository-senior-archivists', 'repository-collection-managers']
                      },
                      {
                        :code => 'merge_archival_record',
                        :groups => ['repository-senior-archivists', 'repository-collection-managers',
                                    'repository-collection-archivists', 'repository-archivists-other',
                                    'repository-transfer-file-issue', 'repository-preservation-team']
                      },
                      {
                        :code => 'manage_rde_templates',
                        :groups => ['repository-senior-archivists', 'repository-collection-managers',
                                    'repository-collection-archivists']
                      },
                      {
                        :code => 'update_container_record',
                        :groups => ['repository-senior-archivists', 'repository-collection-managers',
                                    'repository-collection-archivists', 'repository-transfer-file-issue',
                                    'repository-preservation-team']
                      },
                      {
                        :code => 'manage_container_record',
                        :groups => ['repository-senior-archivists', 'repository-collection-managers',
                                    'repository-collection-archivists', 'repository-transfer-file-issue',
                                    'repository-preservation-team']
                      },
                      {
                        :code => 'manage_container_profile_record',
                        :groups => ['repository-senior-archivists', 'repository-collection-managers',
                                    'repository-collection-archivists', 'repository-transfer-file-issue',
                                    'repository-preservation-team']
                      },
                      {
                        :code => 'manage_location_profile_record',
                        :groups => ['repository-senior-archivists', 'repository-collection-managers',
                                    'repository-collection-archivists', 'repository-transfer-file-issue',
                                    'repository-preservation-team']
                      },
                      {
                        :code => 'create_job',
                        :groups => ['repository-senior-archivists', 'repository-collection-managers',
                                    'repository-collection-archivists', 'repository-archivists-other',
                                    'repository-transfer-file-issue', 'repository-preservation-team']
                      },
                      {
                        :code => 'cancel_job',
                        :groups => ['repository-senior-archivists', 'repository-collection-managers',
                                    'repository-collection-archivists', 'repository-archivists-other',
                                    'repository-transfer-file-issue', 'repository-preservation-team']
                      },
                      {
                        :code => 'update_assessment_record',
                        :groups => ['repository-senior-archivists', 'repository-collection-managers',
                                    'repository-collection-archivists', 'repository-archivists-other',
                                    'repository-preservation-team']
                      },
                      {
                        :code => 'delete_assessment_record',
                        :groups => ['repository-senior-archivists', 'repository-collection-managers',
                                    'repository-preservation-team']
                      },
                      {
                        :code => 'manage_assessment_attributes',
                        :groups => ['repository-senior-archivists', 'repository-collection-managers',
                                    'repository-preservation-team']
                      },
                     ]


    new_perms = [
                 {
                   :code => 'manage_publication',
                   :description => 'The ability to publish and unpublish records to the public website',
                   :groups => ['repository-senior-archivists', 'repository-collection-managers']
                 },
                 {
                   :code => 'manage_reading_room_requests',
                   :description => 'The ability to process reading room requests',
                   :groups => ['repository-senior-archivists', 'repository-collection-managers',
                               'repository-collection-archivists', 'repository-archivists-other',
                               'repository-transfer-file-issue', 'repository-reading-room-staff',
                               'repository-preservation-team']
                 },
                 {
                   :code => 'set_raps',
                   :description => 'The ability to set Restricted Access Periods on records',
                   :groups => ['repository-senior-archivists', 'repository-collection-managers',
                               'repository-collection-archivists', 'repository-archivists-other',
                               'repository-transfer-file-issue']
                 },
                 {
                   :code => 'manage_conservation_assessment',
                   :description => 'The ability to create, modify and delete conversion requests and assessments',
                   :groups => ['repository-senior-archivists', 'repository-collection-managers',
                               'repository-preservation-team']
                 },
                 {
                   :code => 'manage_fee_schedules',
                   :description => 'The ability to create, modify and delete fee schedules',
                   :groups => ['repository-senior-archivists', 'repository-collection-managers']
                 },
                 {
                   :code => 'manage_transfers',
                   :description => 'The ability to manage transfers',
                   :groups => ['repository-senior-archivists', 'repository-collection-managers',
                               'repository-transfer-file-issue']
                 },
                 {
                   :code => 'manage_file_issues',
                   :description => 'The ability to manage file issues',
                   :groups => ['repository-senior-archivists', 'repository-collection-managers',
                               'repository-transfer-file-issue']
                 },
                 {
                   :code => 'approve_closed_records',
                   :description => 'The ability to mark closed records approved from agency',
                   :groups => ['repository-senior-archivists', 'repository-collection-managers',
                               'repository-collection-archivists', 'repository-archivists-other',
                               'repository-reading-room-staff']
                 },
                 {
                   :code => 'manage_agency_deletion',
                   :description => 'The ability to manage the deletion of agency records',
                   :groups => ['repository-senior-archivists', 'repository-collection-managers',
                               'repository-archivists-other']
                 },
                 {
                   :code => 'approve_records',
                   :description => 'The ability to archivist approve a record',
                   :groups => ['repository-senior-archivists', 'repository-collection-managers',
                               'repository-collection-archivists', 'repository-archivists-other']
                 },
                ]

    now = Time.now

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
