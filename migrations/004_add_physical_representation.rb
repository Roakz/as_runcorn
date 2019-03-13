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
      DynamicEnum :contained_within_id, :null => false
      TextField :description
      TextField :exhibition_history
      TextField :exhibition_notes
      Integer :exhibition_quality, :default => 0
      Integer :file_issue_allowed, :default => 1
      DynamicEnum :format_id, :null => false
      DynamicEnum :intended_use_id
      String :original_registration_date
      TextField :physical_format_details
      TextField :preferred_citation
      TextField :preservation_notes
      DynamicEnum :preservation_priority_rating_id
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

    create_editable_enum('runcorn_format',
                [
                  'Not Set',
                  'Drafting Cloth (Linen)',
                  'Magnetic Media',
                  'Magnetic Media -- Cartridge Tape',
                  'Magnetic Media -- Cassette Tape',
                  'Magnetic Media -- Floppy Disk',
                  'Magnetic Media -- Hard Disc Drive',
                  'Magnetic Media -- Reel Tape',
                  'Magnetic Media -- Reel Tape -- 7 Track',
                  'Magnetic Media -- Reel Tape -- 9 Track',
                  'Magnetic Media -- Reel Tape -- 21 Track',
                  'Magnetic Media -- Video Tape',
                  'Magnetic Media -- Video Tape -- Betamax',
                  'Magnetic Media -- Video Tape -- U-Matic',
                  'Magnetic Media -- Video Tape -- VHS',
                  'Microform',
                  'Microform -- Aperture Cards',
                  'Microform -- Aperture Cards -- Acetate',
                  'Microform -- Aperture Cards -- Cellulose',
                  'Microform -- Aperture Cards -- Nitrate',
                  'Microform -- Aperture Cards -- Silver Halide',
                  'Microform -- Microfiche',
                  'Microform -- Microfiche -- Acetate',
                  'Microform -- Microfiche -- Cellulose',
                  'Microform -- Microfiche -- Nitrate',
                  'Microform -- Microfiche -- Silver Halide',
                  'Microform -- Microfilm',
                  'Microform -- Microfilm -- Acetate',
                  'Microform -- Microfilm -- Cellulose',
                  'Microform -- Microfilm -- Nitrate',
                  'Microform -- Microfilm -- Silver Halide',
                  'Motion Picture Film',
                  'Motion Picture Film -- 8 mm',
                  'Motion Picture Film -- 9.5 mm',
                  'Motion Picture Film -- 16 mm',
                  'Motion Picture Film -- 35 mm',
                  'Motion Picture Film -- 70 mm',
                  'Motion Picture Film -- Super 8',
                  'Negative, Slide or Transparency',
                  'Negative, Slide or Transparency -- Glass Plate Negative',
                  'Negative, Slide or Transparency -- Lantern Slide',
                  'Negative, Slide or Transparency -- Mounted Slide Frame',
                  'Negative, Slide or Transparency -- Mounted Slide Frame -- 110 Slide',
                  'Negative, Slide or Transparency -- Mounted Slide Frame -- 126 Slide',
                  'Negative, Slide or Transparency -- Mounted Slide Frame -- 127 Slide',
                  'Negative, Slide or Transparency -- Mounted Slide Frame -- 127 Super Slide',
                  'Negative, Slide or Transparency -- Mounted Slide Frame -- 35 mm Half Frame Slide',
                  'Negative, Slide or Transparency -- Mounted Slide Frame -- 35 mm Slide',
                  'Negative, Slide or Transparency -- Polyester Negative',
                  'Object',
                  'Object -- Glass',
                  'Object -- Metal',
                  'Object -- Plastic',
                  'Object -- Stone',
                  'Object -- Textile',
                  'Object -- Wood',
                  'Optical Media',
                  'Optical Media -- Compact Disc (CD)',
                  'Optical Media -- Digital Versatile Disc (DVD)',
                  'Paper',
                  'Paper -- Blueprint',
                  'Paper -- Cardboard',
                  'Paper -- Mounted',
                  'Paper -- Synthetic',
                  'Paper -- Tracing / Offset',
                  'Phonographic Media',
                  'Phonographic Media -- Acetate',
                  'Phonographic Media -- Shellac',
                  'Phonographic Media -- Vinyl Disc',
                  'Phonographic Media -- Wax Cylinder',
                  'Photographic Print',
                  'Photographic Print -- Album',
                  'Photographic Print -- Framed',
                  'Photographic Print -- Loose',
                  'Photographic Print -- Mounted',
                  'Photographic Print -- Sleeved',
                  'Plastic Film',
                  'Vellum or Parchment',
                  'Volume',
                  'Volume -- Bolted',
                  'Volume -- Kalamazoo',
                  'Volume -- Locked',
                ])

    create_enum('runcorn_salvage_priority_code',
                ['AIC', 'BHG', 'LOW'])



    create_editable_enum('runcorn_physical_representation_contained_within',
                         [
                           'ALB', 'ARCBX', 'BUN', 'CBX', 'CDR', 'FLM', 'MBX',
                           'NAA', 'OTH', 'PHBX', 'SLD', 'SOLBX', 'TYPE1',
                           'TYPE10', 'TYPE11', 'TYPE2', 'TYPE31', 'TYPE51',
                           'TYPE6',
                         ])

    create_enum('runcorn_preservation_priority_rating', ['High', 'Medium', 'Low'])
    create_enum('runcorn_intended_use', [
                  'Master',
                  'Access Copy',
                  'Preservation Copy',
                  'Backup Copy',
                ])


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
