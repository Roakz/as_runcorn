require 'csv'
require_relative 'runcorn_report'

class AgencyLoansReport < RuncornReport

  def initialize(from_date, to_date)
    @from_date = from_date
    @to_date = to_date

    # Reverse dates if they're backwards.
    if @from_date && @to_date && @from_date > @to_date
      @from_date, @to_date = @to_date, @from_date
    end
  end

  def file_issue_request_dataset(aspacedb, mapdb)
    base_ds = mapdb[:file_issue_request]
                .filter(:draft => 0)

    if @from_date
      from_time = @from_date.to_time.to_i * 1000
      base_ds = base_ds.where { Sequel.qualify(:file_issue_request, :create_time) >= from_time }
    end

    if @to_date
      to_time = @to_date.to_time.to_i * 1000
      base_ds = base_ds.where { Sequel.qualify(:file_issue_request, :create_time) <= to_time }
    end

    counts = base_ds
               .left_join(:file_issue_request_item, Sequel.qualify(:file_issue_request_item, :file_issue_request_id) => Sequel.qualify(:file_issue_request, :id))
               .group_and_count(Sequel.qualify(:file_issue_request, :id))
               .map {|row|
                 [row[:id], row[:count]]
               }.to_h

    aspace_agency_ids = base_ds
                          .join(:agency, Sequel.qualify(:agency, :id) => Sequel.qualify(:file_issue_request, :agency_id))
                          .select(:aspace_agency_id)
                          .map {|row| row[:aspace_agency_id]}

    aspace_agency_map = build_aspace_agency_map(aspacedb, aspace_agency_ids)

    base_ds
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

  def file_issue_dataset(aspacedb, mapdb, issue_type)
    base_ds = mapdb[:file_issue]
               .filter(:issue_type => issue_type)

    if @from_date
      from_time = @from_date.to_time.to_i * 1000
      base_ds = base_ds.where { Sequel.qualify(:file_issue, :create_time) >= from_time }
    end

    if @to_date
      to_time = @to_date.to_time.to_i * 1000
      base_ds = base_ds.where { Sequel.qualify(:file_issue, :create_time) <= to_time }
    end

    counts = base_ds
               .left_join(:file_issue_item, Sequel.qualify(:file_issue_item, :file_issue_id) => Sequel.qualify(:file_issue, :id))
               .group_by(Sequel.qualify(:file_issue, :id))
               .select(Sequel.qualify(:file_issue, :id),
                       Sequel.as(Sequel.lit('count(*)'), :count),
                       Sequel.as(Sequel.lit('min(expiry_date)'), :min_expiry_date),
                       Sequel.as(Sequel.lit('max(expiry_date)'), :max_expiry_date))
               .map {|row|
                 [row[:id], row]
               }.to_h

    overdue_file_issue_ids = base_ds
                             .join(:file_issue_item, Sequel.qualify(:file_issue_item, :file_issue_id) => Sequel.qualify(:file_issue, :id))
                             .filter(:not_returned => 0)
                             .filter(:returned_date => nil)
                             .filter(Sequel.~(:expiry_date => nil))
                             .where { expiry_date < Date.today }
                             .select(Sequel.qualify(:file_issue, :id))
                             .map {|row|
                               [row[:id], true]
                             }.to_h

    aspace_agency_ids = base_ds
                          .join(:agency, Sequel.qualify(:agency, :id) => Sequel.qualify(:file_issue, :agency_id))
                          .select(:aspace_agency_id)
                          .map {|row| row[:aspace_agency_id]}

    aspace_agency_map = build_aspace_agency_map(aspacedb, aspace_agency_ids)


    base_ds
      .join(:agency, Sequel.qualify(:agency, :id) => Sequel.qualify(:file_issue, :agency_id))
      .join(:agency_location, Sequel.qualify(:agency_location, :id) => Sequel.qualify(:file_issue, :agency_location_id))
      .select_all(:file_issue)
      .select_append(Sequel.qualify(:agency, :aspace_agency_id))
      .select_append(Sequel.as(Sequel.qualify(:agency_location, :name), :agency_location_name))
      .each do |row|
      row[:count] = counts.fetch(row[:id], {}).fetch(:count, 0)
      row[:min_expiry_date] = counts.fetch(row[:id], {}).fetch(:min_expiry_date, nil)
      row[:max_expiry_date] = counts.fetch(row[:id], {}).fetch(:max_expiry_date, nil)
      row[:agency_qsa_id] = QSAId.prefixed_id_for(AgentCorporateEntity, aspace_agency_map.fetch(row[:aspace_agency_id]).fetch(:qsa_id))
      row[:agency_name] = aspace_agency_map.fetch(row[:aspace_agency_id]).fetch(:sort_name)
      row[:has_overdue] = overdue_file_issue_ids.fetch(row[:id], false)
      yield row
    end
  end

  def search_request_dataset(aspacedb, mapdb)
    base_ds = mapdb[:search_request]
                .filter(:draft => 0)

    if @from_date
      from_time = @from_date.to_time.to_i * 1000
      base_ds = base_ds.where { Sequel.qualify(:search_request, :create_time) >= from_time }
    end

    if @to_date
      to_time = @to_date.to_time.to_i * 1000
      base_ds = base_ds.where { Sequel.qualify(:search_request, :create_time) <= to_time }
    end

    aspace_agency_ids = base_ds
                          .join(:agency, Sequel.qualify(:agency, :id) => Sequel.qualify(:search_request, :agency_id))
                          .select(:aspace_agency_id)
                          .map {|row| row[:aspace_agency_id]}

    aspace_agency_map = build_aspace_agency_map(aspacedb, aspace_agency_ids)

    base_ds
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

          file_issue_dataset(aspacedb, mapdb, 'PHYSICAL') do |row|
            csv << [
              "%s%s%s" % [QSAId.prefix_for(FileIssue), 'P', row[:id]],
              row[:count],
              row[:agency_qsa_id],
              row[:agency_name],
              row[:status],
              row[:request_type],
              row[:agency_location_name],
              row[:delivery_location],
              [row[:min_expiry_date], row[:max_expiry_date]].compact.uniq.join(' - '),
              row[:has_overdue] ? 'true' : '',
            ]
          end

          file_issue_dataset(aspacedb, mapdb, 'DIGITAL') do |row|
            csv << [
              "%s%s%s" % [QSAId.prefix_for(FileIssue), 'D', row[:id]],
              row[:count],
              row[:agency_qsa_id],
              row[:agency_name],
              row[:status],
              row[:request_type],
              row[:agency_location_name],
              row[:delivery_location],
              [row[:min_expiry_date], row[:max_expiry_date]].compact.uniq.join(' - '),
              '',
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
