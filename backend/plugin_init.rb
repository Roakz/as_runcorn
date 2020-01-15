require_relative '../common/validations'
require_relative '../common/qsa_id'
require_relative '../common/qsa_id_registrations'
require_relative '../common/movement_context_manager'
require_relative '../common/search_utils'

require_relative 'lib/batch_action_handler'

# load batch action handlers
Dir.glob(File.join(File.dirname(__FILE__), 'lib',  'batch_action_handlers', "*.rb")).sort.each do |file|
  require file
end

Permission.define("manage_agency_registration",
                  "The ability to manage the agency registration workflow",
                  :level => "repository")

Permission.define("approve_agency_registration",
                  "The ability to approve the registration of a draft agency",
                  :implied_by => "manage_agency_registration",
                  :level => "global")

Permission.define('manage_publication',
                  'The ability to publish and unpublish records to the public website',
                  :level => "repository")

Permission.define('update_publish_flag',
                  'The ability to publish and unpublish records to the public website',
                  :implied_by => "manage_publication",
                  :level => "global")

Permission.define('set_raps',
                  'The ability to set Restricted Access Periods on records',
                  :level => "repository")

Permission.define('manage_conservation_assessment',
                  'The ability to create, modify and delete conversion requests and assessments',
                  :level => "repository")

Permission.define('manage_fee_schedules',
                  'The ability to create, modify and delete fee schedules',
                  :level => "repository")

Permission.define('update_charges',
                  'The ability to create, modify and delete chargeable services and items',
                  :implied_by => "manage_fee_schedules",
                  :level => "global")

Permission.define('manage_agency_deletion',
                  'The ability to manage the deletion of agency records',
                  :level => "repository")

Permission.define('delete_agency',
                  'The ability to delete agency records',
                  :implied_by => "manage_agency_deletion",
                  :level => "global")

# These permissions are not relevant the QSA, so hide them to avoid confusion
[
 "update_accession_record",
 "update_event_record",
 "delete_event_record",
 "suppress_archival_record",
 "view_suppressed",
 "update_classification_record",
 "delete_classification_record",
].each do |perm|
  Permission.hide(perm)
end


begin
  History.register_model(ChargeableItem)
  History.register_model(ChargeableService)
  History.register_model(Batch)
rescue NameError
  Log.info("Unable to register new models for history. Please install the as_history plugin")
end

require_relative 'lib/file_storage'
require_relative 'lib/s3_authenticated_storage'
require_relative 'lib/byte_storage'

# Config test!
ByteStorage.get

TreeReordering.add_after_reorder_hook do |target_class, child_class, target_id, child_ids, position|
  if child_class == ArchivalObject
    resource = if target_class == Resource
                 Resource.get_or_die(target_id)
               else
                 ao = ArchivalObject.get_or_die(target_id)
                 Resource.get_or_die(ao.root_record_id)
               end

    Resource.rap_needs_propagate(resource.id)

    DB.open do |db|
      rap = if target_class == Resource
              db[:rap]
                .filter(:resource_id => target_id)
                .first
            else
              applied_rap_id = db[:rap_applied]
                                 .filter(:"#{target_class.table_name}_id" => target_id)
                                 .filter(:is_active => 1)
                                 .first[:rap_id]

              RAP[applied_rap_id]
            end

      unless rap.nil? || rap[:default_for_repo_id]
        if rap[:archival_object_id]
          RAP.force_unpublish_for_restricted(ArchivalObject, rap[:archival_object_id])
        elsif rap[:resource_id]
          RAP.force_unpublish_for_restricted(Resource, rap[:resource_id])
        end
      end
    end
  end
end


require_relative 'lib/rap_provisioner'

ArchivesSpaceService.plugins_loaded_hook do
  # Make sure the default RAP exists from the outset
  Repository.each do |repository|
    next if repository.repo_code == Repository.GLOBAL

    RequestContext.open(:repo_id => repository.id) do
      DB.attempt {
        RAP.get_default_id
      }.and_if_constraint_fails do |e|
        Log.warn("Constraint failure while creating default RAP: #{e}")
      end
    end
  end

  unless AppConfig.has_key?(:qsa_skip_rap_provisioning) && AppConfig[:qsa_skip_rap_provisioning]
    RapProvisioner.doit!
  end

  if AppConfig.has_key?(:create_big_series)
    series_count = AppConfig[:create_big_series]
    RequestContext.open(:repo_id => 2) do
      resource = Resource.create_from_json(JSONModel::JSONModel(:resource).from_hash(
                                             "title" => "TEST RECORD - big series with #{series_count} AOs",
                                             "dates" => [{
                                                           "date_type" => "single",
                                                           "label" => "creation",
                                                           "begin" => "1901",
                                                           "end" => "2020",
                                                         }],
                                             "id_0" => SecureRandom.hex,
                                             "level" => "collection",
                                             "language" => "eng",
                                             "extents" => [{"portion" => "whole", "number" => "5 or so", "extent_type" => "reels"}],
                                             "series_system_agent_relationships" => [
                                               {
                                                 'jsonmodel_type' => 'series_system_agent_record_ownership_relationship',
                                                 'relator' => 'is_controlled_by',
                                                 'start_date' => "2000-01-01",
                                                 'ref' => "/agents/corporate_entities/1",
                                               }
                                             ]
                                           ))

      count = 0

      DB.open do |db|
        batch = []

        base_qsa_id = Sequence.get("QSA_ID_ARCHIVAL_OBJECT")
        base_representation_qsa_id = Sequence.get("QSA_ID_PHYSICAL_REPRESENTATION")
        top_container_id = db[:top_container].insert(:lock_version => 1,
                                                     :json_schema_version => 1,
                                                     :type_id => 317,
                                                     :current_location_id => 1719,
                                                     :indicator => "BIG1",
                                                     :repo_id => 2,
                                                     :create_time => Time.now,
                                                     :system_mtime => Time.now,
                                                     :user_mtime => Time.now)

        series_count.times do |count|
          rando = SecureRandom.hex
          row = {
            :lock_version => 1,
            :json_schema_version => 1,
            :repo_id => 2,
            :root_record_id => resource.id,
            :parent_name => "root@/repositories/2/resources/#{resource.id}",
            :position => count,
            :publish => 0,
            :ref_id => rando,
            :title => "Component #{rando}",
            :display_string => "Component #{rando}",
            :level_id => 890,
            :create_time => Time.now,
            :system_mtime => Time.now,
            :user_mtime => Time.now,
            :qsa_id => base_qsa_id + count,
            :significance_id => 2798,
            :significance_is_sticky => 0,
          }

          batch << row

          if batch.size == 1000 || (count + 1) == series_count
            db[:archival_object].multi_insert(batch)

            first_inserted_id = db["select LAST_INSERT_ID()"].get(:"LAST_INSERT_ID()")
            ids = (first_inserted_id...(first_inserted_id + batch.length)).to_a

            batch = []

            db[:date].multi_insert(ids.map {|id|
                                     {
                                       :lock_version => 0,
                                       :json_schema_version => 1,
                                       :archival_object_id => id,
                                       :date_type_id => 1281,
                                       :label_id => 916,
                                       :begin => '1900',
                                       :end => '2050',
                                       :create_time => Time.now,
                                       :system_mtime => Time.now,
                                       :user_mtime => Time.now,
                                       :created_by => 'admin',
                                       :last_modified_by => 'admin',
                                     }
                                   })

            if AppConfig.has_key?(:create_big_series_with_representations) && AppConfig[:create_big_series_with_representations]
              db[:physical_representation].multi_insert(ids.each_with_index.map {|id, idx|
                {
                  :lock_version => 0,
                  :repo_id => 2,
                  :archival_object_id => id,
                  :resource_id => resource.id,
                  :title => "REP #{idx}",
                  :qsa_id => base_representation_qsa_id + count + idx,
                  :current_location_id => 2381, #HOME
                  :normal_location_id => 2381,
                  :contained_within_id => 1819, #ARCBX
                  :format_id => 1782, #Object
                  :create_time => Time.now,
                  :system_mtime => Time.now,
                  :user_mtime => Time.now,
                  :created_by => 'admin',
                  :last_modified_by => 'admin',
                }
              })

              first_inserted_rep_id = db["select LAST_INSERT_ID()"].get(:"LAST_INSERT_ID()")
              rep_ids = (first_inserted_rep_id...(first_inserted_rep_id + ids.length)).to_a

              db[:representation_container_rlshp].multi_insert(rep_ids.map{|rep_id| {
                :physical_representation_id => rep_id,
                :top_container_id => top_container_id,
                :aspace_relationship_position => 0,
                :system_mtime => Time.now,
                :user_mtime => Time.now,
                :created_by => 'admin',
                :last_modified_by => 'admin',
              }})
            end

            count += 1000
            $stderr.puts("Created #{count} AOs so far")
          end
        end

        db[:sequence].filter(:sequence_name => "QSA_ID_ARCHIVAL_OBJECT").update(:value => base_qsa_id + count + 1)
        if AppConfig.has_key?(:create_big_series_with_representations) && AppConfig[:create_big_series_with_representations]
          db[:sequence].filter(:sequence_name => "QSA_ID_PHYSICAL_REPRESENTATION").update(:value => base_representation_qsa_id + count + 1)
        end
      end

      Resource.rap_needs_propagate(resource.id)
    end
  end

  Search.add_search_hook do |params|
    if params[:aq]
      params[:aq] = SearchUtils.rewrite_top_container_identifier_queries(params[:aq])
    end

    params
  end
end

ASModel.all_models.each do |model|
  if model.included_modules.include?(Publishable)
    model.include(PublicationPolice)
  end
end
