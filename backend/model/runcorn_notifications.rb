class RuncornNotifications

  attr_accessor :current_username

  DEFAULT_NOTIFICATION_WINDOW_DAYS = 7

  def initialize(from_date = nil)
    @from_date = DateParse.date_parse_down(from_date) || (Date.today - DEFAULT_NOTIFICATION_WINDOW_DAYS)
    @current_username = RequestContext.get(:current_username)
    @user = User[:username => @current_username]
    @permissions_cache = {}
  end

  Notification = Struct.new(:qsa_id, :uri, :at, :by, :source_system) do
    def to_json(*args)
      to_h.to_json
    end
  end

  def to_json(*args)
    to_hash.to_json
  end

  def can?(permission_code)
    if @permissions_cache.has_key?(permission_code)
      return @permissions_cache[permission_code]
    end

    result = @user.can?(permission_code)
    @permissions_cache[permission_code] = result
    result
  end

  def parse_record_from_row(row)
    if row[:file_issue_request_id]
      [
          QSAId.prefixed_id_for(FileIssueRequest, row[:file_issue_request_id]),
          JSONModel::JSONModel(:file_issue_request).uri_for(row[:file_issue_request_id]),
          :manage_file_issues,
      ]
    elsif row[:file_issue_id]
      [
          FileIssue.qsa_id_prefixed(row[:file_issue_qsa_id], :issue_type => row[:issue_type]),
          JSONModel::JSONModel(:file_issue).uri_for(row[:file_issue_id]),
          :manage_file_issues,
      ]
    elsif row[:transfer_proposal_id]
      [
          QSAId.prefixed_id_for(TransferProposal, row[:transfer_proposal_id]),
          JSONModel::JSONModel(:transfer_proposal).uri_for(row[:transfer_proposal_id]),
          :manage_transfers,
      ]
    elsif row[:transfer_id]
      [
          QSAId.prefixed_id_for(Transfer, row[:transfer_qsa_id]),
          JSONModel::JSONModel(:transfer).uri_for(row[:transfer_id]),
          :manage_transfers,
      ]

    elsif row[:search_request_id]
      [
          QSAId.prefixed_id_for(SearchRequest, row[:search_request_id]),
          JSONModel::JSONModel(:search_request).uri_for(row[:search_request_id]),
          :manage_search_requests,
      ]
    else
      nil
    end
  end

  def to_hash
    result = []
    seen = {}


    MAPDB.open do |mapdb|
      from_time = @from_date.to_time.to_i * 1000
      mapdb[:conversation]
        .join(:handle, Sequel.qualify(:handle, :id) => Sequel.qualify(:conversation, :handle_id))
        .left_join(:file_issue, Sequel.qualify(:handle, :file_issue_id) => Sequel.qualify(:file_issue, :id))
        .left_join(:transfer, Sequel.qualify(:handle, :transfer_id) => Sequel.qualify(:transfer, :id))
        .filter(Sequel.|({ Sequel.qualify(:conversation, :source_system) => 'ARCHIVES_GATEWAY' },
                         Sequel.&({ Sequel.qualify(:conversation, :source_system) => 'ARCHIVESSPACE' },
                                  Sequel.~(Sequel.qualify(:conversation, :created_by) => current_username))))
        .where{ Sequel.qualify(:conversation, :create_time) >= from_time }
        .order(Sequel.desc(Sequel.qualify(:conversation, :create_time)))
        .select_all(:conversation, :handle)
        .select_append(Sequel.qualify(:file_issue, :issue_type),
                       Sequel.as(Sequel.qualify(:file_issue, :qsa_id), :file_issue_qsa_id),
                       Sequel.as(Sequel.qualify(:transfer, :qsa_id), :transfer_qsa_id))
        .map do |row|
          qsa_id, uri, required_permission = parse_record_from_row(row)

          next if qsa_id.nil? || seen[qsa_id]
          next unless can?(required_permission)

          seen[qsa_id] = true

          result << Notification.new(qsa_id,
                                     uri,
                                     row[:create_time],
                                     row[:created_by],
                                     row[:source_system])
        end
    end

    result
  end

end
