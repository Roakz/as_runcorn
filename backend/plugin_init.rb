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

    resource.propagate_raps!
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

  RapProvisioner.doit!

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

      resource.propagate_raps!
    end
  end
end
