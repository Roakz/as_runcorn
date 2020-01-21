require 'csv'
require_relative 'runcorn_report'

class AgencyTransferProposalsReport < RuncornReport

  def initialize(from_date, to_date)
    @from_date = from_date
    @to_date = to_date

    # Reverse dates if they're backwards.
    if @from_date && @to_date && @from_date > @to_date
      @from_date, @to_date = @to_date, @from_date
    end
  end

  def transfer_dataset(aspacedb, mapdb)
    base_ds = mapdb[:transfer_proposal].filter(Sequel.~(Sequel.qualify(:transfer_proposal, :status) => 'INACTIVE'))

    if @from_date
      from_time = @from_date.to_time.to_i * 1000
      base_ds = base_ds.where { Sequel.qualify(:transfer_proposal, :create_time) >= from_time }
    end

    if @to_date
      to_time = @to_date.to_time.to_i * 1000
      base_ds = base_ds.where { Sequel.qualify(:transfer_proposal, :create_time) <= to_time }
    end

    aspace_agency_ids = base_ds
                          .join(:agency, Sequel.qualify(:agency, :id) => Sequel.qualify(:transfer_proposal, :agency_id))
                          .select(:aspace_agency_id)
                          .map {|row| row[:aspace_agency_id]}

    aspace_agency_map = build_aspace_agency_map(aspacedb, aspace_agency_ids)

    base_ds
      .join(:agency, Sequel.qualify(:agency, :id) => Sequel.qualify(:transfer_proposal, :agency_id))
      .join(:agency_location, Sequel.qualify(:agency_location, :id) => Sequel.qualify(:transfer_proposal, :agency_location_id))
      .left_join(:transfer, Sequel.qualify(:transfer, :transfer_proposal_id) => Sequel.qualify(:transfer_proposal, :id))
      .select_all(:transfer_proposal)
      .select_append(Sequel.qualify(:agency, :aspace_agency_id))
      .select_append(Sequel.as(Sequel.qualify(:agency_location, :name), :agency_location_name))
      .select_append(Sequel.as(Sequel.qualify(:transfer, :id), :transfer_id))
      .select_append(Sequel.as(Sequel.qualify(:transfer, :date_scheduled), :transfer_date_scheduled))
      .each do |row|
      row[:agency_qsa_id] = QSAId.prefixed_id_for(AgentCorporateEntity, aspace_agency_map.fetch(row[:aspace_agency_id]).fetch(:qsa_id))
      row[:agency_name] = aspace_agency_map.fetch(row[:aspace_agency_id]).fetch(:sort_name)
      yield row
    end
  end

  def to_stream
    tempfile = Tempfile.new('AgencyTransferProposalsReport')

    CSV.open(tempfile, 'w') do |csv|
      csv << ['ID (P)', 'Transfer Title', 'Transfer ID', 'Agency ID', 'Agency Title', 'Status', 'Request Date']
      DB.open do |aspacedb|
        MAPDB.open do |mapdb|
          transfer_dataset(aspacedb, mapdb) do |row|
            csv << [
              QSAId.prefixed_id_for(TransferProposal, row[:id]),
              row[:title],
              row[:transfer_id] ? QSAId.prefixed_id_for(Transfer, row[:transfer_id]) : nil,
              row[:agency_qsa_id],
              row[:agency_name],
              row[:status],
              row[:transfer_date_scheduled],
            ]
          end
        end
      end
    end

    tempfile.rewind
    tempfile
  end

end
