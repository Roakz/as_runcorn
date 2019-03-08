require 'db/migrations/utils'

Sequel.migration do

  up do
    create_table(:physical_representation) do
      primary_key :id
      Integer :lock_version, :default => 0, :null => false

      Integer :repo_id, :null => false

      Integer :archival_object_id
      Integer :resource_id

      DynamicEnum :access_category_id
      DynamicEnum :current_location_id, :null => false
      DynamicEnum :normal_location_id, :null => false
      DynamicEnum :access_clearance_procedure_id
      DynamicEnum :accessioned_status_id
      String :agency_assigned_id
      String :approval_date
      DynamicEnum :colour_id
      DynamicEnum :contained_within_id
      TextField :description
      TextField :exhibition_history
      TextField :exhibition_notes
      Integer :exhibition_quality, :default => 0
      Integer :file_issue_allowed, :default => 1
      DynamicEnum :format_id, :null => false
      DynamicEnum :intended_use_id
      String :original_registration_date
      DynamicEnum :physical_description_type_id
      TextField :preferred_citation
      TextField :preservation_notes
      DynamicEnum :preservation_restriction_status_id, :null => false
      TextField :remark
      String :title
      DynamicEnum :salvage_priority_code_id
      Integer :sterilised_status, :default => 0
      Integer :publish

      apply_mtime_columns
    end

    alter_table(:physical_representation) do
      add_foreign_key([:repo_id], :repository, :key => :id)
      add_foreign_key([:archival_object_id], :archival_object, :key => :id)
      add_foreign_key([:resource_id], :resource, :key => :id)
    end

    create_enum('runcorn_access_category', [
                  '000', '001', '002', '003', '004', '005', '006', '007', '008', '009', '010',
                  '011', '012', '013', '014', '015', '016', '017', '018', '019', '020', '021',
                  '022', '023', '024', '025', '026', '027', '028', '029', '030', '031', '032',
                  '033', '034', '035', '036', '037', '038', '039', '040', '041', '042', '043',
                  '044', '045', '046', '047', '048', '049', '050', '051', '052', '053', '054',
                  '055', '056', '057', '058', '059', '060', '061', '062', '063', '064', '065',
                  '066', '067', '068', '069', '070', '071', '072', '073', '074', '075', '076',
                  '077', '078', '079', '080', '081', '082', '083', '084', '085', '086', '087',
                  '088', '089', '090', '091', '092', '093', '094', '095', '096', '097', '098',
                  '099', '100', '101', '102', '999', 'CON', 'DEA', 'DES', 'MAS', 'NAP', 'OVR',
                  'PRA', 'REF', 'TEM',
                ])

    create_enum('runcorn_location',
                ['ATT', 'CAM', 'COND', 'CONS', 'CPH', 'DIG', 'DISC', 'EXH', 'EXTWEB', 'FIL',
                 'FVT', 'JOL', 'MIC', 'MSS', 'N/A', 'OUT', 'PER', 'PSR', 'REF', 'REF SCAN', 'REP',
                 'REP2', 'REPRO', 'SCAN PART', 'SCAN RR', 'SCANNED', 'SCANNED EX', 'SEE CON', 'SORTRM',
                 'VAULT1', 'VAULT2'])


    create_enum('runcorn_access_clearance_procedure',
                ['ADMIN',
                 'BLANK',
                 'OPEN',
                 'RTI',
                ])

    create_enum('runcorn_accessioned_status',
                ['ACCSSN',
                 'DEACC',
                 'DESTR',
                 'PEND_DEACC',
                 'PEND_DESTR',
                ])

    create_enum('runcorn_colour',
                ['COL',
                 'MON',
                ])

    create_enum('runcorn_format',
                ['A/V', 'AER', 'ARC', 'ART', 'CAR', 'COM',
                 'FCH', 'FIL', 'FLM', 'GRA', 'LFFLM', 'MAP', 'MIC', 'MMF', 'MSC',
                 'NEG', 'OBJ', 'OTH', 'PAS', 'PHO', 'TEC', 'VOL', ])

    create_enum('runcorn_salvage_priority_code',
                ['AIC', 'BHG', 'LOW'])


    create_enum('runcorn_physical_representation_contained_within', ['FIXME'])
    create_enum('runcorn_physical_description_type', ['FIXME'])
    create_enum('runcorn_physical_preservation_restriction_status', ['FIXME'])
    create_enum('runcorn_intended_use', ['FIXME'])


    create_table(:representation_approved_by_rlshp) do
      primary_key :id

      Integer :physical_representation_id
      Integer :agent_person_id

      Integer :aspace_relationship_position

      apply_mtime_columns(false)
    end

    alter_table(:representation_approved_by_rlshp) do
      add_foreign_key([:physical_representation_id], :physical_representation, :key => :id)
      add_foreign_key([:agent_person_id], :agent_person, :key => :id)
    end

    alter_table(:deaccession) do
      add_column(:physical_representation_id, :integer,  :null => true)
      add_foreign_key([:physical_representation_id], :physical_representation, :key => :id, :name => 'deaccession_physrep_id_fk')
    end

    alter_table(:extent) do
      add_column(:physical_representation_id, :integer,  :null => true)
      add_foreign_key([:physical_representation_id], :physical_representation, :key => :id, :name => 'extent_physrep_id_fk')
    end

    alter_table(:external_id) do
      add_column(:physical_representation_id, :integer,  :null => true)
      add_foreign_key([:physical_representation_id], :physical_representation, :key => :id, :name => 'external_id_physrep_id_fk')
    end
  end

  down do
  end

end
