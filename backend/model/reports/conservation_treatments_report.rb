require 'csv'
require_relative 'runcorn_report'

class ConservationTreatmentsReport < RuncornReport

  def initialize(from_date, to_date)
    @from_date = from_date
    @to_date = to_date

    # Reverse dates if they're backwards.
    if @from_date && @to_date && @from_date > @to_date
      @from_date, @to_date = @to_date, @from_date
    end
  end

  def to_stream
    tempfile = Tempfile.new('ConservationTreatmentsReport')

    CSV.open(tempfile, 'w') do |csv|
      csv << ['Conservation Requests (CR)',
              'Assessement ID (AS)',
              'Agency ID (A)',
              'Series ID (S)',
              'Series Title',
              'Record ID (ITM)',
              'Physcial Reperesentation ID (PR)',
              'Format',
              'Status',
              'Treatment Process',
              'Treatments Applied',
              'Number of Treatments applied',
              'Materials Used - Consumables',
              'Materials Used - Staff Time',
              'Date Conservation Required By',
              'Date Commenced',
              'Date Completed',
              'Created By']

      DB.open do |aspacedb|
        base_ds = aspacedb[:conservation_request]

        if @from_date
          from_time = @from_date.to_time.to_i * 1000
          base_ds = base_ds.where { Sequel.qualify(:conservation_request, :create_time) >= from_time }
        end

        if @to_date
          to_time = (@to_date + 1).to_time.to_i * 1000 - 1
          base_ds = base_ds.where { Sequel.qualify(:conservation_request, :create_time) <= to_time }
        end

        base_ds
          .each do |row|
          csv << [
          ]
        end
      end
    end

    tempfile.rewind
    tempfile
  end

end
