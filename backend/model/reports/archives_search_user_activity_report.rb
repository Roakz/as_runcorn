require_relative 'runcorn_report'
require 'csv'

class ArchivesSearchUserActivityReport < RuncornReport

  def initialize(from_date, to_date)
    @from_date = from_date
    @to_date = to_date

    # Reverse dates if they're backwards.
    if @from_date && @to_date && @from_date > @to_date
      @from_date, @to_date = @to_date, @from_date
    end
  end

  def to_stream
    tempfile = Tempfile.new('AgencyLoansReport')

    CSV.open(tempfile, 'w') do |csv|
      csv << ['User ID',
              'User Name',
              'Registration Date',
              'Verified',
              'Status',
              'Admin',
              'Last Login Date?',
              'Open Requests',
              'Date Made Inactive',
              'Reason Made Inactive']

      PublicDB.open do |publicdb|
        base_ds = publicdb[:user]

        if @from_date
          from_time = @from_date.to_time.to_i * 1000
          base_ds = base_ds.where { Sequel.qualify(:user, :create_time) >= from_time }
        end

        if @to_date
          to_time = (@to_date + 1).to_time.to_i * 1000 - 1
          base_ds = base_ds.where { Sequel.qualify(:user, :create_time) <= to_time }
        end

        # find all "active" requests
        users_with_active_orders_map = {}
        publicdb[:reading_room_request]
          .filter(Sequel.~(Sequel.qualify(:reading_room_request, :status) => ['COMPLETE', 'REJECTED_BY_AGENCY', 'CANCELLED_BY_QSA', 'CANCELLED_BY_RESEARCHER']))
          .filter(Sequel.qualify(:reading_room_request, :user_id) => base_ds.select(:id))
          .distinct(Sequel.qualify(:reading_room_request, :user_id))
          .each do |row|
          users_with_active_orders_map[row[:user_id]] = true
        end

        base_ds
          .order(Sequel.asc(:create_time))
          .each do |row|
          csv << [
            row[:email],
            [row[:last_name], row[:first_name]].compact.reject{|s| s.empty?}.join(', ').strip,
            Time.at(row[:create_time] / 1000).strftime('%d/%m/%Y'),
            row[:verified] == 1 ? 'Y' : 'N',
            row[:inactive] == 1 ? 'Inactive' : 'Active',
            row[:admin] == 1 ? 'Y' : 'N',
            row[:last_login_time] ? Time.at(row[:last_login_time] / 1000).strftime('%d/%m/%Y') : nil,
            users_with_active_orders_map.fetch(row[:id], false) ? 'Y' : 'N',
            row[:inactive_time] ? Time.at(row[:inactive_time] / 1000).strftime('%d/%m/%Y') : nil,
            row[:admin_notes],
          ]
        end
      end
    end

    tempfile.rewind
    tempfile
  end



end