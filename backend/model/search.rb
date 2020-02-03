class Search

  def self.search_csv( params, repo_id )
    criteria = params.map{|k, v| [k.intern, v]}.to_h

    criteria.delete(:facet)
    criteria.delete(:modified_since)
    criteria[:dt] = "json"
    criteria[:page] = 1
    criteria[:page_size] = 500

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
        'Significance Inherited?',
        'Sensitivity Label',
        'Agency Control No.',
        'Previous System Location',
        'Disposal Class',
        'Home Location',
        'Current Location',
        'Availiability',
        'Status',
        'Colour',
        'File Size',
        'File Issue Allowed?',
        'Exhibition Quality?',
        'Intended Use',
        'Original Registration Date',
        'Serialised',
        'Accrual',
        'Reason Requested'
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
    end

    def category_format
    end

    def associated_record_id
    end

    def contained_within
    end

    def top_container
    end

    def rap_status
    end

    def rap_expiry_date
    end

    def access_category
    end

    def rap_publish_details
    end

    def rap_is_inherited
    end

    def significance
    end

    def significance_inherited
    end

    def sensitivity_label
    end

    def availability
    end

    def status
    end

    def colour
    end

    def file_size
    end

    def file_issue_allowed
    end

    def exhibition_quality
    end

    def intended_use
    end

    def original_registration_date
    end

    def serialised
    end

    def accrual
    end

    def reason_requested
    end

    def source
    end

    def responsible_agency_id
    end

    def responsible_agency_name
    end

    def responsible_agency_inherited
    end

    def repository
    end

    def floor
    end

    def room
    end

    def area
    end

    def location_profile
    end

    def treatment_status
    end

    def treatments_applied
    end

    def date_commenced
    end

    def date_completed
    end

    def assessment_id
    end

    def created_date
    end

    def created_by
    end

    def last_modified_date
    end

    def last_modified_by
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
        significance_inherited,
        sensitivity_label,
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
        last_modified_date,
        last_modified_by
      ]
    end
  end
end