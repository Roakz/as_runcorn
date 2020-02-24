class BulkRecordChanges

  extend JSONModel

  ColumnDef = Struct.new(:heading, :maps_to) do
    def initialize(heading, opts = {})
      self.heading = heading
      self.maps_to = opts.fetch(:maps_to, [])

      self
    end
  end

  CREATE_SHEET_NAME = "Records to Create"
  UPDATE_SHEET_NAME = "Records to Update"

  COLUMNS = [
    COLUMN_CREATE_RECORD_TYPE = ColumnDef.new('Record Type to Create (ITM, PR, DR)'),
    COLUMN_PARENT = ColumnDef.new('Parent QSA ID (S, ITM, ROW)'),
    COLUMN_TITLE = ColumnDef.new('Title', maps_to: ['title']),
    COLUMN_DESCRIPTION = ColumnDef.new('Description', maps_to: ['description']),
    COLUMN_FORMAT = ColumnDef.new('Format', maps_to: ['format']),
    COLUMN_START_DATE = ColumnDef.new('Start Date (YYYY, MM/YYYY, DD/MM/YYYY)', maps_to: ['dates/:index/begin']),
    COLUMN_START_DATE_QUALIFIER = ColumnDef.new('Start Date Qualifier', maps_to: ['dates/:index/certainty']),
    COLUMN_END_DATE = ColumnDef.new('End Date (YYYY, MM/YYYY, DD/MM/YYYY)', maps_to: ['dates/:index/end']),
    COLUMN_END_DATE_QUALIFIER = ColumnDef.new('End Date Qualifier', maps_to: ['dates/:index/certainty_end']),
    COLUMN_AGENCY_CONTROL_NUMBER = ColumnDef.new('Agency Control number', maps_to: ['agency_assigned_id']),
    COLUMN_BOX_NUMBER = ColumnDef.new('Box Number', maps_to: ['indicator']),
    COLUMN_CONTAINED_WITHIN = ColumnDef.new('Contained within', maps_to: ['contained_within']),
    COLUMN_SENSITIVITY_LABEL = ColumnDef.new('Sensitivity Label', maps_to: ['sensitivity_label']),
    COLUMN_TRANSFER_ID = ColumnDef.new('Transfer ID', maps_to: ['transfer']),
    COLUMN_PREVIOUS_SYSTEM_ID = ColumnDef.new('Previous System ID', maps_to: ['previous_system_identifiers']),
    COLUMN_SIGNIFICANCE = ColumnDef.new('Significance', maps_to: ['significance']),
    COLUMN_INHERIT_SIGNIFICANCE = ColumnDef.new("Don't inherit Significance changes", maps_to: ['significance_is_sticky']),
    COLUMN_COPYRIGHT_STATUS = ColumnDef.new('Copyright Status', maps_to: ['copyright_status']),
    COLUMN_SUBJECTS = ColumnDef.new('Subjects', maps_to: ['subjects/:index/term']),
    COLUMN_REMARKS = ColumnDef.new('Remarks', maps_to: ['remarks']),

    COLUMN_UPDATE_ID = ColumnDef.new('Record QSA ID (ITM, PR, DR)'),

    COLUMN_UNKNOWN = ColumnDef.new('UNKNOWN COLUMN'),
  ]


  class CreateBatch

    include JSONModel

    def initialize
      @promise_groups = {
        :ao => {},
        :series_by_ao => {},
        :series => {},
        :subject => {},
        :top_container => {},
      }

      @pending_records = []
    end

    PendingRecord = Struct.new(:type, :record_hash, :row, :parent_ref)
    PromiseRef = Struct.new(:row, :ref) do
      def resolve(uri)
        ref['ref'] = uri
      end
    end

    def add_archival_object(ao, row)
      @pending_records << PendingRecord.new(:archival_object, ao, row, nil)
    end

    def add_physical_representation(rep, row, parent_ref)
      @pending_records << PendingRecord.new(:physical_representation, rep, row, parent_ref)
    end

    def add_digital_representation(rep, row, parent_ref)
      @pending_records << PendingRecord.new(:digital_representation, rep, row, parent_ref)
    end

    def promise_for(promise_type, parent_ref, row)
      unless @promise_groups.include?(promise_type)
        raise "Unknown promise type: #{promise_type}"
      end

      promise = PromiseRef.new(row, {'ref' => :unresolved_promise})

      @promise_groups[promise_type][parent_ref] ||= []
      @promise_groups[promise_type][parent_ref] << promise

      promise.ref
    end

    def create(job)
      created_count = @pending_records.length
      errors = []

      # Pass 1: Find an AO that is ready to create and create it (along with
      # any representations that are also listed)
      loop do
        fulfil_promises

        to_create, consumed_entries = find_ao_to_create
        @pending_records -= consumed_entries

        # Like group_by(result.type) but ensuring stable ordering.
        rows_by_type = consumed_entries.reduce({}) do |result, entry|
          result[entry.type] ||= []
          result[entry.type] << entry.row
          result
        end

        if to_create
          begin
            to_create[:level] = 'item'

            obj = ArchivalObject.create_from_json(JSONModel(:archival_object).from_hash(to_create))
            created_id = IDRef.new("ITM%d" % [obj.qsa_id])

            job.write_output("Created Item record: \"#{to_create[:title]}\" with #{consumed_entries.length - 1} representation(s)")

            row_id = IDRef.new("ROW%d" % [consumed_entries.first.row.row_number])

            # Rewrite any promises referencing this record by row
            @promise_groups.each do |promise_type, promises|
              if promise_refs = promises[row_id]
                promises[created_id] = Array(promises[created_id]) + promise_refs
                promises[row_id] = []
              end
            end
          rescue JSONModel::ValidationException => validation_errors
            # Validation errors either correspond to the AO or one of the
            # representation rows.  We need to do some footwork to work out
            # which it is.

            validation_errors.errors.each do |json_property, messages|
              target_row, reported_field = if json_property =~ %r{\Aphysical_representations/([0-9]+)/(.+)\z}
                                             [rows_by_type[:physical_representation][Integer($1)], $2]
                                           elsif json_property =~ %r{\Adigital_representations/([0-9]+)/(.+)\z}
                                             [rows_by_type[:digital_representation][Integer($1)], $2]
                                           else
                                             [rows_by_type[:archival_object][0], json_property]
                                           end

              errors << {
                sheet: CREATE_SHEET_NAME,
                json_property: json_property,
                field: reported_field,
                row: target_row.row_number,
                column: (COLUMNS.find {|column| column.maps_to.include?(reported_field.gsub(%r{/[0-9]+/}, '/:index/'))} || COLUMN_UNKNOWN).heading,
                errors: messages,
              }
            end
          rescue
            raise "$!"
          end
        else
          break
        end
      end

      if errors.length > 0
        raise BulkUpdateFailed.new(errors)
      end

      # Pass 2: Find any representations that are to be created under an
      # existing AO (i.e. an AO that is not listed in this sheet)
      grouped = @pending_records.group_by {|pending| pending.record_hash.dig(:controlling_record, 'ref')}

      grouped.each do |ao_uri, representations|
        # Non-representations will be nil here, and if there are any of those
        # still pending they're probably participating in a dependency cycle.
        next if ao_uri.nil?

        parsed = JSONModel.parse_reference(ao_uri)

        ao = ArchivalObject.get_or_die(parsed[:id])
        ao_json = ArchivalObject.to_jsonmodel(ao)

        # We'll use these arrays to map indexes from reported error fields back
        # to the spreadsheet rows.  We fill out the first N elements with
        # placeholders corresponding to the representations that the AO already
        # had.

        physical_representation_rows = [:placeholder_for_existing_rep] * ao_json.physical_representations.length
        digital_representation_rows = [:placeholder_for_existing_rep] * ao_json.digital_representations.length

        # Slot in our new representations
        representations.each do |representation|
          if representation.type == :physical_representation
            physical_representation_rows << representation.row
            ao_json.physical_representations << representation.record_hash.merge(:normal_location => 'HOME', :current_location => 'HOME')
          else
            digital_representation_rows << representation.row
            ao_json.digital_representations << representation.record_hash.merge(:normal_location => 'HOME')
          end
        end

        begin
          ao.update_from_json(ao_json)
          job.write_output("Added #{representations.length} representation(s) to existing Item record: \"#{ao_json.display_string}\"")
        rescue JSONModel::ValidationException => validation_errors
          validation_errors.errors.each do |json_property, messages|
            target_row, reported_field = if json_property =~ %r{\Aphysical_representations/([0-9]+)/(.+)\z}
                                           [physical_representation_rows[Integer($1)], $2]
                                         elsif json_property =~ %r{\Adigital_representations/([0-9]+)/(.+)\z}
                                           [digital_representation_rows[Integer($1)], $2]
                                         end

            errors << {
              sheet: CREATE_SHEET_NAME,
              json_property: json_property,
              field: reported_field,
              row: target_row.row_number,
              column: (COLUMNS.find {|column| column.maps_to.include?(reported_field.gsub(%r{/[0-9]+/}, '/:index/'))} || COLUMN_UNKNOWN).heading,
              errors: messages,
            }
          end
        end

        # Mark as done
        @pending_records -= representations
      end

      unless @pending_records.empty?
        @pending_records.each do |pending|
          errors << {
            sheet: CREATE_SHEET_NAME,
            row: pending.row.row_number,
            column: COLUMN_PARENT.heading,
            errors: ["record parent could not be created. Please check that your parent references exist and don't make a loop!"],
          }
        end
      end

      if errors.length > 0
        raise BulkUpdateFailed.new(errors)
      end

      created_count
    end

    def update(job)
      updated_count = @pending_records.length
      errors = []

      # Simpler than the create case: here we'll just resolve any subjects
      # and containers.
      fulfil_promises

      # Every pending record is an update to an AO: either directly, or against
      # one of its contained representations.  Group pending records by the AO
      # they ultimately affect.
      update_qsaid_to_ao = {}
      @pending_records.group_by {|pending| IDRef.new(pending.row.fetch(COLUMN_UPDATE_ID)).prefix}.each do |record_type, pending_records|
        qsa_ids = pending_records.map {|pending| IDRef.new(pending.row.fetch(COLUMN_UPDATE_ID)).qsa_id_number}

        case record_type
        when 'ITM'
          ArchivalObject.filter(:qsa_id => qsa_ids).select(:qsa_id, :id).each do |row|
            update_qsaid_to_ao[IDRef.for_qsa_id(ArchivalObject, row[:qsa_id])] = row[:id]
          end
        when 'PR'
          PhysicalRepresentation
            .join(ArchivalObject, Sequel.qualify(:archival_object, :id) => Sequel.qualify(:physical_representation, :archival_object_id))
            .filter(Sequel.qualify(:physical_representation, :qsa_id) => qsa_ids)
            .select(Sequel.qualify(:physical_representation, :qsa_id),
                    Sequel.qualify(:archival_object, :id)).each do |row|
            update_qsaid_to_ao[IDRef.for_qsa_id(PhysicalRepresentation, row[:qsa_id])] = row[:id]
          end
        when 'DR'
          DigitalRepresentation
            .join(ArchivalObject, Sequel.qualify(:archival_object, :id) => Sequel.qualify(:digital_representation, :archival_object_id))
            .filter(Sequel.qualify(:digital_representation, :qsa_id) => qsa_ids)
            .select(Sequel.qualify(:digital_representation, :qsa_id),
                    Sequel.qualify(:archival_object, :id)).each do |row|
            update_qsaid_to_ao[IDRef.for_qsa_id(DigitalRepresentation, row[:qsa_id])] = row[:id]
          end
        end
      end

      @pending_records.group_by {|pending| update_qsaid_to_ao.fetch(IDRef.new(pending.row.fetch(COLUMN_UPDATE_ID)))}.each do |ao_id_for_update, pending_updates|
        ao = ArchivalObject[ao_id_for_update]
        ao_json = ArchivalObject.to_jsonmodel(ao)

        ao_row = nil
        physical_representation_rows = {}
        digital_representation_rows = {}

        pending_updates.each do |pending|
          update_qsa_id = pending.row.fetch(COLUMN_UPDATE_ID)

          target = case pending.type
                        when :archival_object
                          ao_row = pending.row
                          ao_json
                        when :physical_representation
                          idx = ao_json.physical_representations.index {|pr| pr['qsa_id_prefixed'] == update_qsa_id}
                          physical_representation_rows[idx] = pending.row
                          ao_json.physical_representations[idx]
                        when :digital_representation
                          idx = ao_json.digital_representations.index {|pr| pr['qsa_id_prefixed'] == update_qsa_id}
                          digital_representation_rows[idx] = pending.row
                          ao_json.digital_representations[idx]
                        end

          # Apply updates from our pending record where there's a value to take.
          # Empty cells are ignored.
          pending.record_hash.each do |k, v|
            next if v.nil? || (k == :dates && v[0][:begin].to_s.empty?)

            target[k.to_s] = v
          end
        end

        begin
          # We never need to change the position for an existing record
          ao_json['position'] = nil

          ao.update_from_json(ao_json)
          job.write_output("Updated existing Item record: \"#{ao_json.display_string}\"")
        rescue JSONModel::ValidationException => validation_errors
          validation_errors.errors.each do |json_property, messages|
            target_row, reported_field = if json_property =~ %r{\Aphysical_representations/([0-9]+)/(.+)\z}
                                           [physical_representation_rows[Integer($1)], $2]
                                         elsif json_property =~ %r{\Adigital_representations/([0-9]+)/(.+)\z}
                                           [digital_representation_rows[Integer($1)], $2]
                                         else
                                           [ao_row, json_property]
                                         end

            errors << {
              sheet: UPDATE_SHEET_NAME,
              json_property: json_property,
              field: reported_field,
              row: target_row.row_number,
              column: (COLUMNS.find {|column| column.maps_to.include?(reported_field.gsub(%r{/[0-9]+/}, '/:index/'))} || COLUMN_UNKNOWN).heading,
              errors: messages,
            }
          end
        end
      end

      if errors.length > 0
        raise BulkUpdateFailed.new(errors)
      end

      updated_count
    end

    private

    def find_ao_to_create
      @pending_records.each do |pending|
        if pending.type == :archival_object && pending_promise_count(pending.row) == 0
          # Make sure all of its representations (if any) are also ready.
          row_id = IDRef.new("ROW%d" % [pending.row.row_number])
          representations = @pending_records.select {|p|
            [:physical_representation, :digital_representation].include?(p.type) && p.parent_ref == row_id
          }

          if representations.all? {|r| pending_promise_count(r.row) == 0}
            # Load 'em in
            ao = pending.record_hash

            ao[:physical_representations] = []
            ao[:digital_representations] = []

            representations.each do |rep|
              if rep.type == :physical_representation
                ao[:physical_representations] << rep.record_hash.merge(:normal_location => 'HOME', :current_location => 'HOME')
              else
                ao[:digital_representations] << rep.record_hash.merge(:normal_location => 'HOME')
              end
            end

            return [ao, [pending, *representations]]
          end
        end
      end

      return [nil, []]
    end

    def fulfil_promises
      # Map QSAIDs to AO URIs (QSAID -> AO)
      qsa_ids = @promise_groups.fetch(:ao).keys.map(&:qsa_id_number).compact

      ArchivalObject.filter(:qsa_id => qsa_ids).select(:id, :qsa_id).each do |row|
        qsa_id = IDRef.for_qsa_id(ArchivalObject, row[:qsa_id])

        @promise_groups[:ao][qsa_id].each do |promise_ref|
          promise_ref.resolve(ArchivalObject.uri_for(:archival_object,
                                                     row[:id],
                                                     :repo_id => RequestContext.get(:repo_id)))
        end

        @promise_groups[:ao][qsa_id] = []
      end

      # Map QSAIDs to containing Series URIs (i.e. QSAID -> AO -> Containing Resource)
      qsa_ids = @promise_groups.fetch(:series_by_ao).keys.map(&:qsa_id_number).compact

      ArchivalObject.filter(:qsa_id => qsa_ids).select(:root_record_id, :qsa_id).each do |row|
        qsa_id = IDRef.for_qsa_id(ArchivalObject, row[:qsa_id])

        @promise_groups[:series_by_ao][qsa_id].each do |promise_ref|
          promise_ref.resolve(Resource.uri_for(:resource,
                                               row[:root_record_id],
                                               :repo_id => RequestContext.get(:repo_id)))
        end

        @promise_groups[:series_by_ao][qsa_id] = []
      end

      # Map QSAIDs to Series URIs (QSAID -> Resource)
      qsa_ids = @promise_groups.fetch(:series).keys.map(&:qsa_id_number).compact

      Resource.filter(:qsa_id => qsa_ids).select(:id, :qsa_id).each do |row|
        qsa_id = IDRef.for_qsa_id(Resource, row[:qsa_id])

        @promise_groups[:series][qsa_id].each do |promise_ref|
          promise_ref.resolve(Resource.uri_for(:resource,
                                               row[:id],
                                               :repo_id => RequestContext.get(:repo_id)))
        end

        @promise_groups[:series][qsa_id] = []
      end

      # Find an existing subject match, creating one as necessary.
      @promise_groups[:subject].each do |term, promise_refs|
        subject = Subject[:title => term]

        unless subject
          subject = Subject.create_from_json(JSONModel(:subject).from_hash(
                                               source: 'local',
                                               vocabulary: '/vocabularies/1',
                                               terms: [{
                                                         jsonmodel_type: 'term',
                                                         term: term,
                                                         term_type: 'topical',
                                                         vocabulary: '/vocabularies/1',
                                                       }]
                                             ))
        end

        promise_refs.each do |promise_ref|
          promise_ref.resolve(subject.uri)
        end
      end

      @promise_groups[:subject] = {}

      # Find an existing top container match, creating one as necessary.
      @promise_groups[:top_container].each do |box_number, promise_refs|
        container = TopContainer[:indicator => box_number]

        unless container
          container = TopContainer.create_from_json(JSONModel(:top_container).from_hash(
                                                      'indicator' => box_number,
                                                      'type' => 'box',
                                                      'current_location' => 'HOME'))
        end


        promise_refs.each do |promise_ref|
          promise_ref.resolve(container.uri)
        end
      end

      @promise_groups[:top_container] = {}
    end

    # The number of promises needing to be fulfilled for a given row.  If it's
    # zero, the row has no dependencies.
    def pending_promise_count(row)
      count = 0
      @promise_groups.values.each do |promises|
        promises.values.each do |promise_refs|
          count += promise_refs.select {|promise_ref| promise_ref.row == row}.length
        end
      end

      count
    end

  end


  def self.run(filename, job)
    check_sheet(filename)

    {
      added: handle_creates(filename, job),
      updated: handle_updates(filename, job),
    }
  end

  def self.check_sheet(filename)
    errors = []

    rules = {
      COLUMN_PARENT => {required: ['ITM', 'PR', 'DR']},
      COLUMN_TITLE => {required: ['ITM', 'PR', 'DR']},
      COLUMN_FORMAT => {required: ['PR']},
      COLUMN_START_DATE => {required: ['ITM']},
      COLUMN_START_DATE_QUALIFIER => {optional: ['ITM']},
      COLUMN_END_DATE => {optional: ['ITM']},
      COLUMN_END_DATE_QUALIFIER => {optional: ['ITM']},
      COLUMN_AGENCY_CONTROL_NUMBER => {optional: ['ITM', 'PR', 'DR']},
      COLUMN_BOX_NUMBER => {required: ['PR']},
      COLUMN_CONTAINED_WITHIN => {required: ['PR', 'DR']},
      COLUMN_SENSITIVITY_LABEL => {optional: ['ITM']},
      COLUMN_TRANSFER_ID => {optional: ['ITM', 'PR', 'DR']},
      COLUMN_PREVIOUS_SYSTEM_ID => {optional: ['ITM', 'PR', 'DR']},
      COLUMN_SIGNIFICANCE => {optional: ['ITM', 'PR', 'DR']},
      COLUMN_INHERIT_SIGNIFICANCE => {optional: ['ITM', 'PR', 'DR']},
      COLUMN_COPYRIGHT_STATUS => {optional: ['ITM']},
      COLUMN_SUBJECTS => {optional: ['ITM']},
      COLUMN_REMARKS => {optional: ['ITM', 'PR', 'DR']},
    }

    ## Check create sheet
    rows_by_transfer_id = {}

    each_row(filename, CREATE_SHEET_NAME) do |row|
      next if row.empty?

      record_type = row.fetch(COLUMN_CREATE_RECORD_TYPE)

      if record_type.nil?
        errors << {
          sheet: CREATE_SHEET_NAME,
          row: row.row_number,
          column: COLUMN_CREATE_RECORD_TYPE.heading,
          errors: ["must specify the type of record to create (ITM, PR, DR)"],
        }

        next
      end

      errors.concat(check_against_rules(row, rules, record_type, CREATE_SHEET_NAME))

      if transfer_id = row.fetch(COLUMN_TRANSFER_ID)
        rows_by_transfer_id[transfer_id] ||= []
        rows_by_transfer_id[transfer_id] << row
      end
    end

    errors.concat(check_qsa_ids(filename, COLUMN_PARENT, CREATE_SHEET_NAME))

    # Check transfer IDs
    MAPDB.open do |mapdb|
      existing_transfer_ids = mapdb[:transfer].filter(:id => rows_by_transfer_id.keys.map(&:to_i)).select(:id).map {|row| row[:id]}

      missing_transfer_ids = rows_by_transfer_id.keys.reject {|k|
        i = k.to_i
        i > 0 && existing_transfer_ids.include?(i)
      }

      missing_transfer_ids.each do |missing_id|
        rows_by_transfer_id.fetch(missing_id, []).each do |row|
          errors << {
            sheet: CREATE_SHEET_NAME,
            row: row.row_number,
            column: COLUMN_TRANSFER_ID.heading,
            errors: ["transfer ID could not be found"],
          }
        end
      end
    end

    ## Check update sheet
    utter_update_failure = false

    update_rules = rules.map {|column, rules|
      rules = rules.clone

      rules[:optional] ||= []
      rules[:optional].concat(Array(rules[:required]))
      rules.delete(:required)
      [column, rules]
    }.to_h

    each_row(filename, UPDATE_SHEET_NAME) do |row|
      next if row.empty?

      record_type = row.fetch(COLUMN_UPDATE_ID)

      if record_type.nil?
        errors << {
          sheet: UPDATE_SHEET_NAME,
          row: row.row_number,
          column: COLUMN_UPDATE_ID.heading,
          errors: ["record to update must be specified"],
        }

        utter_update_failure = true
        next
      elsif !['ITM', 'PR', 'DR'].include?(IDRef.new(record_type).prefix)
        errors << {
          sheet: UPDATE_SHEET_NAME,
          row: row.row_number,
          column: COLUMN_UPDATE_ID.heading,
          errors: ["record type not supported for update"],
        }

        utter_update_failure = true
        next
      end

      unless utter_update_failure
        errors.concat(check_against_rules(row, update_rules, IDRef.new(record_type).prefix, UPDATE_SHEET_NAME))
      end
    end

    unless utter_update_failure
      errors.concat(check_qsa_ids(filename, COLUMN_UPDATE_ID, UPDATE_SHEET_NAME))
    end

    ## Freak out!
    unless errors.empty?
      raise BulkUpdateFailed.new(errors)
    end
  end


  def self.check_qsa_ids(filename, column, sheet_name)
    rows_by_record_id = {}

    each_row(filename, sheet_name) do |row|
      if record_id = row.fetch(column)
        record_id = IDRef.new(record_id)

        if record_id.qsa_id_number
          rows_by_record_id[record_id] ||= []
          rows_by_record_id[record_id] << row
        end
      end
    end

    missing_qsa_ids = []

    rows_by_record_id.keys.group_by(&:prefix).each do |record_type, qsa_idrefs|
      case record_type
      when 'ITM'
        found_qsa_ids = ArchivalObject.filter(:qsa_id => qsa_idrefs.map(&:qsa_id_number)).select(:qsa_id).map {|row| row[:qsa_id]}
        missing_qsa_ids.concat(qsa_idrefs.reject {|id| found_qsa_ids.include?(id.qsa_id_number) })
      when 'S'
        found_qsa_ids = Resource.filter(:qsa_id => qsa_idrefs.map(&:qsa_id_number)).select(:qsa_id).map {|row| row[:qsa_id]}
        missing_qsa_ids.concat(qsa_idrefs.reject {|id| found_qsa_ids.include?(id.qsa_id_number) })
      when 'PR'
        found_qsa_ids = PhysicalRepresentation.filter(:qsa_id => qsa_idrefs.map(&:qsa_id_number)).select(:qsa_id).map {|row| row[:qsa_id]}
        missing_qsa_ids.concat(qsa_idrefs.reject {|id| found_qsa_ids.include?(id.qsa_id_number) })
      when 'DR'
        found_qsa_ids = DigitalRepresentation.filter(:qsa_id => qsa_idrefs.map(&:qsa_id_number)).select(:qsa_id).map {|row| row[:qsa_id]}
        missing_qsa_ids.concat(qsa_idrefs.reject {|id| found_qsa_ids.include?(id.qsa_id_number) })
      else
        # Not a supported type
        Log.warn("#{record_type} is not supported by the bulk record change spreadsheet importer.")
        missing_qsa_ids.concat(qsa_idrefs)
      end
    end

    errors = []

    missing_qsa_ids.each do |missing_parent_qsaid|
      rows_by_record_id.fetch(missing_parent_qsaid, []).each do |row|
        errors << {
          sheet: sheet_name,
          row: row.row_number,
          column: column.heading,
          errors: ["referenced record could not be found (#{missing_parent_qsaid.ref})"],
        }
      end
    end

    errors
  end

  def self.check_against_rules(row, rules, record_type, sheet_name)
    errors = []

    rules.each do |column, rule|
      next unless row.has_heading?(column)

      value = row.fetch(column)

      if value.nil? && rule.fetch(:required, []).include?(record_type)
        errors << {
          sheet: sheet_name,
          row: row.row_number,
          column: column.heading,
          errors: ["is a required field for #{record_type} record types"],
        }

        next
      end

      if value && (!rule.fetch(:required, []).include?(record_type) && !rule.fetch(:optional, []).include?(record_type))
        errors << {
          sheet: sheet_name,
          row: row.row_number,
          column: column.heading,
          errors: ["is not a supported field for #{record_type} record types"],
        }

        next
      end
    end

    errors
  end


  def self.handle_creates(filename, job)
    batch = CreateBatch.new

    each_row(filename, CREATE_SHEET_NAME) do |row|
      next if row.empty?

      case row.fetch(COLUMN_CREATE_RECORD_TYPE)
          when 'ITM'
            process_archival_object(row, batch)
          when 'PR'
            # This is a special case for the error handling as we create Top
            # Containers as a part of fulfilling promises, separate to the act
            # of creating any individual record.  This makes it hard to map the
            # resulting error back to any specific row, so we do that upfront.
            if row.fetch(COLUMN_BOX_NUMBER).nil?
              errors = [
                {
                  sheet: CREATE_SHEET_NAME,
                  json_property: 'top_container/indicator',
                  field: 'indicator',
                  row: row.row_number,
                  column: COLUMN_BOX_NUMBER.heading,
                  errors: ["field is required for Physical Representations"],
                }
              ]


              raise BulkUpdateFailed.new(errors)
            end

            process_physical_representation(row, batch)
          when 'DR'
            process_digital_representation(row, batch)
      end
    end

    batch.create(job)
  end


  def self.handle_updates(filename, job)
    batch = CreateBatch.new

    # Items to update might be AOs, PRs or DRs.  To update representations, we
    # need to find their controlling record and update that.  One complication
    # is that the controlling record might also be listed for update in our
    # sheet, and so we'd like to combine the updates to an AO with the updates
    # to its representations.

    errors = []

    each_row(filename, UPDATE_SHEET_NAME) do |row|
      next if row.empty?

      record_id = IDRef.new(row.fetch(COLUMN_UPDATE_ID))

      unless record_id.qsa_id_number
        errors << {
          sheet: CREATE_SHEET_NAME,
          json_property: 'id',
          field: 'id',
          row: row.row_number,
          column: COLUMN_UPDATE_ID.heading,
          errors: ["field must refer to an existing record"],
        }

        next
      end

      if record_id.is_archival_object?
        process_archival_object(row, batch)
      elsif record_id.is_physical_representation?
        process_physical_representation(row, batch)
      elsif record_id.is_digital_representation?
        process_digital_representation(row, batch)
      end
    end

    unless errors.empty?
      raise BulkUpdateFailed.new(errors)
    end

    batch.update(job)
  end


  def self.reformat_date(s)
    s.to_s.split(/\D+/).reverse.map {|d| d.rjust(2, '0')}.join('-')
  end

  def self.process_archival_object(row, batch)
    record = {}

    # If we're mapping records for creation
    if row.has_heading?(COLUMN_PARENT)
      parent_ref = IDRef.new(row.fetch(COLUMN_PARENT))

      if parent_ref.is_archival_object?
        # We're an AO that is the child of another AO.
        record[:parent] = batch.promise_for(:ao, parent_ref, row)
        record[:resource] = batch.promise_for(:series_by_ao, parent_ref, row)
      else
        # We're a top-level AO.  Our parent is the series.
        record[:resource] = batch.promise_for(:series, parent_ref, row)
      end
    end

    record[:title] = row.fetch(COLUMN_TITLE)
    record[:description] = row.fetch(COLUMN_DESCRIPTION)

    record[:publish] = false
    record[:archivist_approved] = false

    record[:dates] = [{
                      :jsonmodel_type => 'date',
                      :begin => reformat_date(row.fetch(COLUMN_START_DATE)),
                      :certainty => row.fetch(COLUMN_START_DATE_QUALIFIER),
                      :end => reformat_date(row.fetch(COLUMN_END_DATE)),
                      :certainty_end => row.fetch(COLUMN_END_DATE_QUALIFIER),
                      :label => 'existence',
                      :date_type => 'inclusive',
                    }]


    record[:agency_assigned_id] = row.fetch(COLUMN_AGENCY_CONTROL_NUMBER)
    record[:sensitivity_label] = row.fetch(COLUMN_SENSITIVITY_LABEL)

    if transfer_id = row.fetch(COLUMN_TRANSFER_ID, nil)
      record[:transfer] = {
        'ref' => "/transfers/#{transfer_id}"
      }
    end

    record[:previous_system_identifiers] = row.fetch(COLUMN_PREVIOUS_SYSTEM_ID)

    if row.has_heading?(COLUMN_SIGNIFICANCE)
      record[:significance] = row.fetch(COLUMN_SIGNIFICANCE)
      record[:significance_is_sticky] = row.fetch(COLUMN_INHERIT_SIGNIFICANCE) == 'Y'
    end

    record[:copyright_status] = row.fetch(COLUMN_COPYRIGHT_STATUS)

    if remarks = row.fetch(COLUMN_REMARKS)
      record[:notes] = [
        {
          'jsonmodel_type' => 'note_singlepart',
          'type' => 'remarks',
          'content' => [remarks],
        }
      ]
    end

    if subjects = row.fetch(COLUMN_SUBJECTS)
      record[:subjects] = subjects
                          .split(/ *; */)
                          .map(&:strip)
                          .reject(&:empty?)
                          .map {|subject|
        batch.promise_for(:subject, subject, row)
      }
    end

    batch.add_archival_object(record, row)
  end

  def self.process_physical_representation(row, batch)
    record = {}

    parent_ref = nil

    if row.has_heading?(COLUMN_PARENT)
      parent_ref = IDRef.new(row.fetch(COLUMN_PARENT))

      if parent_ref.qsa_id_number
        record[:controlling_record] = batch.promise_for(:ao, parent_ref, row)
      end
    end

    record[:title] = row.fetch(COLUMN_TITLE)
    record[:description] = row.fetch(COLUMN_DESCRIPTION)
    record[:format] = row.fetch(COLUMN_FORMAT)

    record[:publish] = false
    record[:archivist_approved] = false

    if row.fetch(COLUMN_BOX_NUMBER)
      record[:container] = batch.promise_for(:top_container, row.fetch(COLUMN_BOX_NUMBER), row)
    end

    record[:contained_within] = row.fetch(COLUMN_CONTAINED_WITHIN)

    record[:agency_assigned_id] = row.fetch(COLUMN_AGENCY_CONTROL_NUMBER)

    if transfer_id = row.fetch(COLUMN_TRANSFER_ID, nil)
      record[:transfer] = {
        'ref' => "/transfers/#{transfer_id}"
      }
    end

    record[:previous_system_identifiers] = row.fetch(COLUMN_PREVIOUS_SYSTEM_ID)

    if row.has_heading?(COLUMN_SIGNIFICANCE)
      record[:significance] = row.fetch(COLUMN_SIGNIFICANCE)
      record[:significance_is_sticky] = row.fetch(COLUMN_INHERIT_SIGNIFICANCE) == 'Y'
    end

    record[:remarks] = row.fetch(COLUMN_REMARKS)

    batch.add_physical_representation(record, row, parent_ref)
  end

  def self.process_digital_representation(row, batch)
    record = {}

    parent_ref = nil

    if row.has_heading?(COLUMN_PARENT)
      parent_ref = IDRef.new(row.fetch(COLUMN_PARENT))
      if parent_ref.qsa_id_number
        record[:controlling_record] = batch.promise_for(:ao, parent_ref, row)
      end
    end

    record[:title] = row.fetch(COLUMN_TITLE)
    record[:description] = row.fetch(COLUMN_DESCRIPTION)

    record[:publish] = false
    record[:archivist_approved] = false

    record[:contained_within] = row.fetch(COLUMN_CONTAINED_WITHIN)

    record[:agency_assigned_id] = row.fetch(COLUMN_AGENCY_CONTROL_NUMBER)

    if transfer_id = row.fetch(COLUMN_TRANSFER_ID, nil)
      record[:transfer] = {
        'ref' => "/transfers/#{transfer_id}"
      }
    end

    if row.has_heading?(COLUMN_SIGNIFICANCE)
      record[:significance] = row.fetch(COLUMN_SIGNIFICANCE)
    end

    record[:remarks] = row.fetch(COLUMN_REMARKS)

    batch.add_digital_representation(record, row, parent_ref)
  end

  def self.each_row(filename, sheet_specifier)
    headers = nil

    XLSXStreamingReader.new(filename).each(sheet_specifier).each_with_index do |row, idx|
      if idx == 0
        # Info row is ignored
        next
      elsif idx == 1
        headers = row_values(row)
      else
        yield Row.new(headers.zip(row_values(row)).to_h, idx + 1)
      end
    end
  end

  def self.row_values(row)
    row.map {|s|
      if s.is_a?(Time)
        # Reformat to what we're expecting
        s.strftime('%d/%m/%Y')
      else
        result = s.to_s.strip
        result.empty? ? nil : result
      end
    }
  end

  class IDRef
    attr_reader :ref

    def to_s
      "#<IDRef ref=#{ref}>"
    end

    def self.for_qsa_id(model, qsa_id_number)
      new(QSAId.prefixed_id_for(model, qsa_id_number))
    end

    def initialize(qsa_id_or_row_ref)
      @ref = qsa_id_or_row_ref.upcase
    end

    def prefix
      @ref.gsub(/[0-9]+$/, '')
    end

    def is_archival_object?
      @ref.start_with?("ITM") || @ref.start_with?("ROW")
    end

    def is_physical_representation?
      @ref.start_with?("PR")
    end

    def is_digital_representation?
      @ref.start_with?("DR")
    end

    def qsa_id_number
      if @ref.start_with?("ROW")
        # Our in-sheet references don't have QSA IDs
        nil
      else
        Integer(QSAId.parse_prefixed_id(@ref).fetch(:id))
      end
    end

    def hash
      @ref.hash
    end

    def ==(other)
      other.is_a?(IDRef) && @ref == other.ref
    end

    def eql?(other)
      self == other
    end

  end

  class BulkUpdateFailed < StandardError
    attr_reader :errors

    def initialize(errors)
      @errors = errors
    end

    def to_json
      @errors
    end
  end

  Row = Struct.new(:values, :row_number) do
    def has_heading?(column)
      self.values.include?(column.heading)
    end

    def fetch(*args)
      args[0] = args[0].heading

      self.values.fetch(*args)
    end

    def empty?
      values.all?{|_, v| v.to_s.strip.empty?}
    end
  end

end
