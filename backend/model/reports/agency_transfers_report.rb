require 'csv'
require_relative 'runcorn_report'

class AgencyTransfersReport < RuncornReport

  def initialize(from_date, to_date)
    @from_date = from_date
    @to_date = to_date

    # Reverse dates if they're backwards.
    if @from_date && @to_date && @from_date > @to_date
      @from_date, @to_date = @to_date, @from_date
    end
  end

  def transfer_dataset(aspacedb, mapdb)
    base_ds = mapdb[:transfer]

    if @from_date
      from_time = @from_date.to_time.to_i * 1000
      base_ds = base_ds.where { Sequel.qualify(:transfer, :create_time) >= from_time }
    end

    if @to_date
      to_time = @to_date.to_time.to_i * 1000
      base_ds = base_ds.where { Sequel.qualify(:transfer, :create_time) <= to_time }
    end

    aspace_agency_ids = base_ds
                          .join(:agency, Sequel.qualify(:agency, :id) => Sequel.qualify(:transfer, :agency_id))
                          .select(:aspace_agency_id)
                          .map {|row| row[:aspace_agency_id]}

    aspace_agency_map = build_aspace_agency_map(aspacedb, aspace_agency_ids)

    aspace_transfer_counts_map = aspacedb[:archival_object]
                                   .filter(:transfer_id => base_ds.select(:id).map{|row| row[:id]})
                                   .group_and_count(:transfer_id)
                                   .map {|row| [row[:transfer_id], row[:count]]}.to_h

    base_ds
      .join(:agency, Sequel.qualify(:agency, :id) => Sequel.qualify(:transfer, :agency_id))
      .join(:agency_location, Sequel.qualify(:agency_location, :id) => Sequel.qualify(:transfer, :agency_location_id))
      .select_all(:transfer)
      .select_append(Sequel.qualify(:agency, :aspace_agency_id))
      .select_append(Sequel.as(Sequel.qualify(:agency_location, :name), :agency_location_name))
      .each do |row|
      row[:item_count] = aspace_transfer_counts_map.fetch(row[:id], 0)
      row[:agency_qsa_id] = QSAId.prefixed_id_for(AgentCorporateEntity, aspace_agency_map.fetch(row[:aspace_agency_id]).fetch(:qsa_id))
      row[:agency_name] = aspace_agency_map.fetch(row[:aspace_agency_id]).fetch(:sort_name)
      yield row
    end
  end

  def to_stream
    tempfile = Tempfile.new('AgencyTransfersReport')

    CSV.open(tempfile, 'w') do |csv|
      csv << ['ID(T)', 'ID (P)', 'Transfer Title', 'Agency ID', 'Agency Title', 'Status', 'Item numbers', 'Quantity Received', 'Date Received', 'Agency Location']
      DB.open do |aspacedb|
        MAPDB.open do |mapdb|
          transfer_dataset(aspacedb, mapdb) do |row|
            csv << [
              QSAId.prefixed_id_for(Transfer, row[:id]),
              QSAId.prefixed_id_for(TransferProposal, row[:transfer_proposal_id]),
              row[:title],
              row[:agency_qsa_id],
              row[:agency_name],
              row[:status],
              row[:item_count],
              row[:quantity_received],
              row[:date_received],
              row[:agency_location_name],
            ]
          end
        end
      end
    end

    tempfile.rewind
    tempfile
  end

end
