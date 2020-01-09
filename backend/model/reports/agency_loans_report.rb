require 'csv'


class AgencyLoansReport

  def initialize(from_date, to_date)
    @from_date = from_date
    @to_date = to_date
  end

  def file_issue_request_dataset(aspacedb, mapdb)
    counts = mapdb[:file_issue_request]
               .filter(:draft => 0)
               .left_join(:file_issue_request_item, Sequel.qualify(:file_issue_request_item, :file_issue_request_id) => Sequel.qualify(:file_issue_request, :id))
               .group_and_count(Sequel.qualify(:file_issue_request, :id))
               .map {|row|
                 [row[:id], row[:count]]
               }.to_h

    aspace_agency_ids = mapdb[:file_issue_request]
                          .filter(:draft => 0)
                          .join(:agency, Sequel.qualify(:agency, :id) => Sequel.qualify(:file_issue_request, :agency_id))
                          .select(:aspace_agency_id)
                          .map {|row| row[:aspace_agency_id]}

    aspace_agency_map = build_aspace_agency_map(aspacedb, aspace_agency_ids)

    mapdb[:file_issue_request]
      .filter(:draft => 0)
      .join(:agency, Sequel.qualify(:agency, :id) => Sequel.qualify(:file_issue_request, :agency_id))
      .join(:agency_location, Sequel.qualify(:agency_location, :id) => Sequel.qualify(:file_issue_request, :agency_location_id))
      .select_all(:file_issue_request)
      .select_append(Sequel.qualify(:agency, :aspace_agency_id))
      .select_append(Sequel.as(Sequel.qualify(:agency_location, :name), :agency_location_name))
      .each do |row|
      row[:count] = counts.fetch(row[:id], 0)
      row[:agency_qsa_id] = QSAId.prefixed_id_for(AgentCorporateEntity, aspace_agency_map.fetch(row[:aspace_agency_id]).fetch(:qsa_id))
      row[:agency_name] = aspace_agency_map.fetch(row[:aspace_agency_id]).fetch(:sort_name)
      yield row
    end
  end

  def build_aspace_agency_map(aspacedb, aspace_agency_ids)
    aspacedb[:name_corporate_entity]
      .join(:agent_corporate_entity, Sequel.qualify(:agent_corporate_entity, :id) => Sequel.qualify(:name_corporate_entity, :agent_corporate_entity_id))
      .filter(:agent_corporate_entity_id => aspace_agency_ids)
      .filter(:is_display_name => 1)
      .select(Sequel.qualify(:agent_corporate_entity, :id),
              Sequel.qualify(:agent_corporate_entity, :qsa_id),
              Sequel.qualify(:name_corporate_entity, :sort_name))
      .map {|row|
        [row[:id], row]
      }.to_h
  end

  def file_issue_physical_dataset(aspacedb, mapdb)
    counts = mapdb[:file_issue]
               .filter(:issue_type => 'PHYSICAL')
               .left_join(:file_issue_item, Sequel.qualify(:file_issue_item, :file_issue_id) => Sequel.qualify(:file_issue, :id))
               .group_and_count(Sequel.qualify(:file_issue, :id))
               .map {|row|
                 [row[:id], row[:count]]
               }.to_h

    aspace_agency_ids = mapdb[:file_issue]
                          .filter(:issue_type => 'PHYSICAL')
                          .join(:agency, Sequel.qualify(:agency, :id) => Sequel.qualify(:file_issue, :agency_id))
                          .select(:aspace_agency_id)
                          .map {|row| row[:aspace_agency_id]}

    aspace_agency_map = build_aspace_agency_map(aspacedb, aspace_agency_ids)

    mapdb[:file_issue]
      .filter(:issue_type => 'PHYSICAL')
      .join(:agency, Sequel.qualify(:agency, :id) => Sequel.qualify(:file_issue, :agency_id))
      .join(:agency_location, Sequel.qualify(:agency_location, :id) => Sequel.qualify(:file_issue, :agency_location_id))
      .select_all(:file_issue)
      .select_append(Sequel.qualify(:agency, :aspace_agency_id))
      .select_append(Sequel.as(Sequel.qualify(:agency_location, :name), :agency_location_name))
      .each do |row|
      row[:count] = counts.fetch(row[:id], 0)
      row[:agency_qsa_id] = QSAId.prefixed_id_for(AgentCorporateEntity, aspace_agency_map.fetch(row[:aspace_agency_id]).fetch(:qsa_id))
      row[:agency_name] = aspace_agency_map.fetch(row[:aspace_agency_id]).fetch(:sort_name)
      yield row
    end
  end

  def file_issue_digital_dataset(aspacedb, mapdb)
    counts = mapdb[:file_issue]
               .filter(:issue_type => 'DIGITAL')
               .left_join(:file_issue_item, Sequel.qualify(:file_issue_item, :file_issue_id) => Sequel.qualify(:file_issue, :id))
               .group_and_count(Sequel.qualify(:file_issue, :id))
               .map {|row|
                 [row[:id], row[:count]]
               }.to_h

    aspace_agency_ids = mapdb[:file_issue]
                          .filter(:issue_type => 'DIGITAL')
                          .join(:agency, Sequel.qualify(:agency, :id) => Sequel.qualify(:file_issue, :agency_id))
                          .select(:aspace_agency_id)
                          .map {|row| row[:aspace_agency_id]}

    aspace_agency_map = build_aspace_agency_map(aspacedb, aspace_agency_ids)

    mapdb[:file_issue]
      .filter(:issue_type => 'DIGITAL')
      .join(:agency, Sequel.qualify(:agency, :id) => Sequel.qualify(:file_issue, :agency_id))
      .join(:agency_location, Sequel.qualify(:agency_location, :id) => Sequel.qualify(:file_issue, :agency_location_id))
      .select_all(:file_issue)
      .select_append(Sequel.qualify(:agency, :aspace_agency_id))
      .select_append(Sequel.as(Sequel.qualify(:agency_location, :name), :agency_location_name))
      .each do |row|
      row[:count] = counts.fetch(row[:id], 0)
      row[:agency_qsa_id] = QSAId.prefixed_id_for(AgentCorporateEntity, aspace_agency_map.fetch(row[:aspace_agency_id]).fetch(:qsa_id))
      row[:agency_name] = aspace_agency_map.fetch(row[:aspace_agency_id]).fetch(:sort_name)
      yield row
    end
  end

  def search_request_dataset(aspacedb, mapdb)
    aspace_agency_ids = mapdb[:search_request]
                          .filter(:draft => 0)
                          .join(:agency, Sequel.qualify(:agency, :id) => Sequel.qualify(:search_request, :agency_id))
                          .select(:aspace_agency_id)
                          .map {|row| row[:aspace_agency_id]}

    aspace_agency_map = build_aspace_agency_map(aspacedb, aspace_agency_ids)

    mapdb[:search_request]
      .filter(:draft => 0)
      .join(:agency, Sequel.qualify(:agency, :id) => Sequel.qualify(:search_request, :agency_id))
      .join(:agency_location, Sequel.qualify(:agency_location, :id) => Sequel.qualify(:search_request, :agency_location_id))
      .select_all(:search_request)
      .select_append(Sequel.qualify(:agency, :aspace_agency_id))
      .select_append(Sequel.as(Sequel.qualify(:agency_location, :name), :agency_location_name))
      .each do |row|
      row[:agency_qsa_id] = QSAId.prefixed_id_for(AgentCorporateEntity, aspace_agency_map.fetch(row[:aspace_agency_id]).fetch(:qsa_id))
      row[:agency_name] = aspace_agency_map.fetch(row[:aspace_agency_id]).fetch(:sort_name)
      yield row
    end
  end

  def to_stream
    tempfile = Tempfile.new('AgencyLoansReport')

    CSV.open(tempfile, 'w') do |csv|
      csv << ['ID', 'ITM (REP) number count', 'Agency (ID)', 'Agency', 'Status', 'Request Type (NRS, RTI, Other)', 'Agency Location', 'Delivery Location', 'Expiry Date', 'Overdue']
      DB.open do |aspacedb|
        MAPDB.open do |mapdb|
          file_issue_request_dataset(aspacedb, mapdb) do |row|
            csv << [
              QSAId.prefixed_id_for(FileIssueRequest, row[:id]),
              row[:count],
              row[:agency_qsa_id],
              row[:agency_name],
              'Digital: %s; Physical: %s' % [row[:digital_request_status], row[:physical_request_status]],
              row[:request_type],
              row[:agency_location_name],
              row[:delivery_location],
              '',
              '',
            ]
          end

          file_issue_physical_dataset(aspacedb, mapdb) do |row|
            csv << [
              "%s%s%s" % [QSAId.prefix_for(FileIssue), 'P', row[:id]],
              row[:count],
              row[:agency_qsa_id],
              row[:agency_name],
              row[:status],
              row[:request_type],
              row[:agency_location_name],
              row[:delivery_location],
              'FIXME',
              'FIXME',
            ]
          end

          file_issue_digital_dataset(aspacedb, mapdb) do |row|
            csv << [
              "%s%s%s" % [QSAId.prefix_for(FileIssue), 'D', row[:id]],
              row[:count],
              row[:agency_qsa_id],
              row[:agency_name],
              row[:status],
              row[:request_type],
              row[:agency_location_name],
              row[:delivery_location],
              'FIXME',
              'FIXME',
            ]
          end

          search_request_dataset(aspacedb, mapdb) do |row|
            csv << [
              QSAId.prefixed_id_for(SearchRequest, row[:id]),
              '',
              row[:agency_qsa_id],
              row[:agency_name],
              row[:status],
              row[:purpose],
              row[:agency_location_name],
              '',
              '',
              '',
            ]
          end
        end
      end
    end

    tempfile.rewind
    tempfile
  end

end