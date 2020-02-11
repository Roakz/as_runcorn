class Search

  def self.search_csv( params, repo_id )
    criteria = params.map{|k, v| [k.intern, v]}.to_h

    criteria.delete(:facet)
    criteria.delete(:modified_since)
    criteria[:dt] = "json"
    criteria[:page] = 1
    criteria[:page_size] = 50

    tempfile = Tempfile.new('SearchExport')

    CSV.open(tempfile, 'w') do |csv|
      csv << [
        'Record Type',
        'ID',
        'Title',
        'Start Date',
        'Certainty',
        'End Date',
        'Certainty',
        'Found In',
        'Published?',
        'Archivist Approved?',
        'Accessioned/ Retention Status',
        'Category/ Format',
        'Associated Record ID',
        'Contained Within',
        'Top Container',
        'RAP Status',
        'RAP Expiry Date',
        'Access Category',
        'RAP Publish Details?',
        'RAP is inherited?',
        'Significance',
        'Inherit Significance?',
        'Sensitivity Label',
        'Agency Control No.',
        'Previous System Location',
        'Disposal Class',
        'Home Location',
        'Current Location',
        'Availability',
        'Status',
        'Colour',
        'File Size',
        'File Issue Allowed?',
        'Exhibition Quality?',
        'Intended Use',
        'Original Registration Date',
        'Serialised?',
        'Accrual?',
        'Reason Requested',
        'Source',
        'Responsible Agency ID',
        'Responsible Agency Name',
        'Responsible Agency Inherited?',
        'Repository',
        'Floor',
        'Room',
        'Area',
        'Location Profile',
        'Treatment Status',
        'Treatments Applied',
        'Date Commenced ',
        'Date Completed',
        'Assessment ID',
        'Created Date',
        'Created By',
        'Last Modified Date',
        'Last Modified By',
      ]

      while(true) do
        result = search(criteria, repo_id)

        break if Array(result['results']).empty?

        result['results'].each do |doc|
          json = ASUtils.json_parse(doc['json'])
          csv << CSVExportRecord.new(doc, json).to_array
        end

        break if result['last_page'] <= result['this_page']

        criteria[:page] = criteria[:page] + 1
      end
    end

    tempfile.rewind
    tempfile
  end

  CSVExportRecord = Struct.new(:doc, :json) do
    def type
      doc['primary_type'].split('_').collect(&:capitalize).join(' ')
    end

    def id
      if doc['primary_type'] == 'top_container' && json['identifier']
        json['identifier']
      elsif json['qsa_id_prefixed']
        json['qsa_id_prefixed']
      else
        JSONModel::JSONModel(doc['primary_type'].intern).id_for(doc['id'])
      end
    end

    def title
      doc['title'] || doc['display_string']
    end

    def start_date
      Array(doc['date_start_u_sstr']).first
    end

    def start_date_certainty
      Array(doc['date_start_certainty_u_sstr']).first
    end

    def end_date
      Array(doc['date_end_u_sstr']).first
    end

    def end_date_certainty
      Array(doc['date_end_certainty_u_sstr']).first
    end

    def found_in
      if ['physical_representation', 'digital_representation'].include?(doc['primary_type'])
        json.dig('controlling_record_series', 'qsa_id_prefixed')
      elsif doc['primary_type'] == 'archival_object'
        Array(json['within']).find{|qsa_id| QSAId.parse_prefixed_id(qsa_id)[:model] == Resource}
      end
    end

    def published
      if json.has_key?('publish')
        json['publish'] ? 'Y' : 'N'
      else
        nil
      end
    end

    def archivist_approved
      if json.has_key?('archivist_approved')
        json['archivist_approved'] ? 'Y' : 'N'
      else
        nil
      end
    end

    def accessioned_retention_status
      if json['retention_status']
        json['retention_status']
      elsif json['accessioned_status']
        json['accessioned_status']
      end
    end

    def category_format
      if json['agency_category']
        json['agency_category']
      elsif json['mandate_type']
        json['mandate_type']
      elsif json['format']
        json['format']
      elsif json['file_type']
        json['file_type']
      elsif doc['primary_type'] == 'top_container'
        if json['container_profile']
          json.dig('container_profile', '_resolved', 'name')
        else
          json['type']
        end
      elsif doc['primary_type'] == 'file_issue_request'
        types = []
        types << 'Physical' if json['physical_request_status'] != 'NONE_REQUESTED'
        types << 'Digital' if json['digital_request_status'] != 'NONE_REQUESTED'

        if type.length > 0
          '%s %s' % [types.join('/'), 'File Issue Request']
        end
      elsif doc['primary_type'] == 'file_issue'
        if json['issue_type'] == 'PHYSICAL'
          'Physical File Issue'
        else
          'Digital File Issue'
        end
      elsif doc['primary_type'] == 'transfer_proposal'
        if Array(json['series']).length > 0
          Array(json['series']).map{|series| series['composition']}.flatten.uniq.sort.join('/')
        end
      elsif doc['primary_type'] == 'transfer'
        if Array(json.dig('transfer_proposal', '_resolved', 'series')).length > 0
          Array(json.dig('transfer_proposal', '_resolved', 'series')).map{|series| series['composition']}.flatten.uniq.sort.join('/')
        end
      elsif json['treatment_priority']
        json['treatment_priority']
      elsif doc['primary_type'] == 'reading_room_request'
        json.dig('requested_item', '_resolved', 'rap_access_status')
      elsif doc['primary_type'] == 'agency_reading_room_request'
        json.dig('requested_item', '_resolved', 'rap_access_status')
      elsif doc['primary_type'] == 'item_use'
        json['item_use_type']
      elsif doc['primary_type'] == 'subject'
        json['terms'].map{|term| term['term_type']}.uniq.join('; ')
      end
    end

    def associated_record_id
      if ['physical_representation', 'digital_representation'].include?(doc['primary_type'])
        json.dig('controlling_record', 'qsa_id_prefixed')
      elsif doc['primary_type'] == 'archival_object'
        Array(json['within']).find{|qsa_id| QSAId.parse_prefixed_id(qsa_id)[:model] == ArchivalObject} ||
          Array(json['within']).find{|qsa_id| QSAId.parse_prefixed_id(qsa_id)[:model] == Resource}
      elsif doc['primary_type'] == 'file_issue'
        if json.dig('file_issue_request', 'ref')
          QSAId.prefixed_id_for(FileIssueRequest, JSONModel::JSONModel(:file_issue_request).id_for(json.dig('file_issue_request', 'ref')))
        end
      elsif doc['primary_type'] == 'transfer'
        json.dig('transfer_proposal', '_resolved', 'qsa_id_prefixed')
      elsif doc['primary_type'] == 'assessment'
        if json['conservation_request_id']
          QSAId.prefixed_id_for(ConservationRequest, json['conservation_request_id'])
        end
      elsif doc['primary_type'] == 'reading_room_request'
        json.dig('requested_item', '_resolved', 'qsa_id_prefixed')
      elsif doc['primary_type'] == 'agency_reading_room_request'
        json.dig('requested_item', '_resolved', 'qsa_id_prefixed')
      end
    end

    def contained_within
      json['contained_within']
    end

    def top_container
      if doc['primary_type'] == 'physical_representation'
        json.dig('container', '_resolved', 'indicator')
      end
    end

    def rap_status
      json['rap_access_status']
    end

    def rap_expiry_date
      if json['rap_expiration']
        if json['expires']
          json.dig('rap_expiration', 'expiry_date')
        else
          'No expiry'
        end
      end
    end

    def access_category
      if json['rap_applied']
        json.dig('rap_applied', 'access_category')
      elsif json['rap_attached']
        json.dig('rap_attached', 'access_category')
      end
    end

    def rap_publish_details
      if json['rap_applied']
        json.dig('rap_applied', 'open_access_metadata') ? 'Y' : 'N'
      elsif json['rap_attached']
        json.dig('rap_attached', 'open_access_metadata') ? 'Y' : 'N'
      end
    end

    def rap_is_inherited
      if json['rap_applied'] && json['rap_attached']
        json.dig('rap_applied', 'uri') == json.dig('rap_attached', 'uri') ? 'N' : 'Y'
      elsif json['rap_applied']
        'N'
      end
    end

    def significance
      json['significance']
    end

    def inherit_significance
      if json.has_key?('significance_is_sticky')
        if json['significance_is_sticky']
          'Y'
        else
          'N'
        end
      end
    end

    def sensitivity_label
      json['sensitivity_label']
    end

    def agency_control_number
      json['agency_assigned_id']
    end

    def previous_system_identifier
      json['previous_system_identifiers']
    end

    def disposal_class
      json['disposal_class']
    end

    def home_location
      Array(doc['top_container_home_location_u_sstr']).first
    end

    def current_location
      Array(doc['current_location_u_sstr']).first
    end

    def availability
      json['calculated_availability']
    end

    def status
      if json['status']
        json['status']
      elsif doc['primary_type'] == 'file_issue_request'
        '%s: %s; %s: %s' % ['Physical', json['physical_request_status'], 'Digital', json['digital_request_status']]
      end
    end

    def colour
      json['colour']
    end

    def file_size
      json['file_size']
    end

    def file_issue_allowed
      if json.has_key?('file_issue_allowed')
        return 'Y' if json['file_issue_allowed'] == 'true'
        return 'N' if json['file_issue_allowed'] == 'false'
        json['file_issue_allowed']
      end
    end

    def exhibition_quality
      if json.has_key?('exhibition_quality')
        json['exhibition_quality'] ? 'Y' : 'N'
      end
    end

    def intended_use
      json['intended_use']
    end

    def original_registration_date
      json['original_registration_date']
    end

    def serialised
      if json['serialised']
        json['serialised'] ? 'Y' : 'N'
      end
    end

    def accrual
      if json['accrual']
        json['accrual'] ? 'Y' : 'N'
      end
    end

    def reason_requested
      if doc['primary_type'] == 'file_issue_request'
        json['request_type']
      elsif doc['primary_type'] == 'file_issue'
        json['request_type']
      elsif doc['primary_type'] == 'search_request'
        json['purpose']
      elsif doc['primary_type'] == 'conservation_request'
        json['reason_requested']
      end
    end

    def source
      if doc['primary_type'] == 'function'
        json['source']
      elsif doc['primary_type'] == 'subject'
        json['source']
      end
    end

    def responsible_agency_id
      json.dig('responsible_agency', '_resolved', 'qsa_id_prefixed')
    end

    def responsible_agency_name
      json.dig('responsible_agency', '_resolved', 'title')
    end

    def responsible_agency_inherited
      if ['physical_representation', 'digital_representation','archival_object'].include?(doc['primary_type'])
        if !!json.dig('responsible_agency', 'inherited')
          'Y'
        else
          'N'
        end
      end
    end

    def repository
      if doc['primary_type'] == 'location'
        json['building']
      end
    end

    def floor
      if doc['primary_type'] == 'location'
        json['floor']
      end
    end

    def room
      if doc['primary_type'] == 'location'
        json['room']
      end
    end

    def area
      if doc['primary_type'] == 'location'
        json['area']
      end
    end

    def location_profile
      if doc['primary_type'] == 'location'
        json.dig('location_profile', '_resolved', 'display_string')
      end
    end

    def treatment_status
      if doc['primary_type'] == 'physical_representation'
        Array(json['conservation_treatments']).map{|ct| ct['status']}.inject(Hash.new(0)) { |h, e| h[e] += 1 ; h }.map{|label, count| '%d %s' % [count, label]}.join('; ')
      end
    end

    def treatments_applied
      if doc['primary_type'] == 'physical_representation'
        Array(json['conservation_treatments']).map{|ct| Array(ct['treatments']).map{|ta| ta['label']}}.flatten.compact.uniq.sort.join('; ')
      end
    end

    def date_commenced
      if doc['primary_type'] == 'physical_representation'
        Array(json['conservation_treatments']).map{|ct| ct['start_date']}.compact.uniq.sort.join('; ')
      end
    end

    def date_completed
      if doc['primary_type'] == 'physical_representation'
        Array(json['conservation_treatments']).map{|ct| ct['end_date']}.compact.uniq.sort.join('; ')
      end
    end

    def assessment_id
      if doc['primary_type'] == 'physical_representation'
        Array(json['conservation_treatments']).map{|ct| ct.dig('assessment', 'ref')}.compact.map{|uri| QSAId.prefixed_id_for(Assessment, JSONModel::JSONModel(:assessment).id_for(uri))}.join('; ')
      end
    end

    def created_date
      if json['create_time']
        Time.parse(json['create_time']).getlocal
      end
    end

    def created_by
      json['created_by']
    end

    def last_modified_date
      if json['user_mtime']
        Time.parse(json['user_mtime']).getlocal
      end
    end

    def last_modified_by
      json['last_modified_by']
    end

    def to_array
      [
        type,
        id,
        title,
        start_date,
        start_date_certainty,
        end_date,
        end_date_certainty,
        found_in,
        published,
        archivist_approved,
        accessioned_retention_status,
        category_format,
        associated_record_id,
        contained_within,
        top_container,
        rap_status,
        rap_expiry_date,
        access_category,
        rap_publish_details,
        rap_is_inherited,
        significance,
        inherit_significance,
        sensitivity_label,
        agency_control_number,
        previous_system_identifier,
        disposal_class,
        home_location,
        current_location,
        availability,
        status,
        colour,
        file_size,
        file_issue_allowed,
        exhibition_quality,
        intended_use,
        original_registration_date,
        serialised,
        accrual,
        reason_requested,
        source,
        responsible_agency_id,
        responsible_agency_name,
        responsible_agency_inherited,
        repository,
        floor,
        room,
        area,
        location_profile,
        treatment_status,
        treatments_applied,
        date_commenced,
        date_completed,
        assessment_id,
        created_date,
        created_by,
        last_modified_date,
        last_modified_by
      ]
    end
  end
end