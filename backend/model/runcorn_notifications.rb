class RuncornNotifications

  DEFAULT_NOTIFICATION_WINDOW_DAYS = 7

  def initialize(from_date = nil)
    @from_date = DateParse.date_parse_down(from_date) || (Date.today - DEFAULT_NOTIFICATION_WINDOW_DAYS)
  end

  Notification = Struct.new(:qsa_id, :uri, :message, :at, :by, :source_system) do
    def to_json(*args)
      to_h.to_json
    end
  end

  def to_json(*args)
    to_hash.to_json
  end

  def qsa_id_and_uri_for_row(row)
    if row[:file_issue_request_id]
      [
          QSAId.prefixed_id_for(FileIssueRequest, row[:file_issue_request_id]),
          JSONModel::JSONModel(:file_issue_request).uri_for(row[:file_issue_request_id])
      ]
    elsif row[:file_issue_id]
      [
          QSAId.prefixed_id_for(FileIssue, row[:file_issue_id]),
          JSONModel::JSONModel(:file_issue).uri_for(row[:file_issue_id])
      ]
    elsif row[:transfer_proposal_id]
      [
          QSAId.prefixed_id_for(TransferProposal, row[:transfer_proposal_id]),
          JSONModel::JSONModel(:transfer_proposal).uri_for(row[:transfer_proposal_id])
      ]
    elsif row[:transfer_id]
      [
          QSAId.prefixed_id_for(Transfer, row[:transfer_id]),
          JSONModel::JSONModel(:transfer).uri_for(row[:transfer_id])
      ]

    elsif row[:search_request_id]
      [
          QSAId.prefixed_id_for(SearchRequest, row[:search_request_id]),
          JSONModel::JSONModel(:search_request).uri_for(row[:search_request_id])
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
        .filter(Sequel.|({ :source_system => 'ARCHIVES_GATEWAY' },
                         Sequel.&({ :source_system => 'ARCHIVESSPACE' },
                                  Sequel.~(:created_by => RequestContext.get(:current_username)))))
        .where{ create_time >= from_time }
        .order(Sequel.desc(:create_time))
        .map do |row|
          qsa_id, uri = qsa_id_and_uri_for_row(row)

          next if qsa_id.nil? || seen[qsa_id]

          seen[qsa_id] = true

          result << Notification.new(qsa_id,
                                     uri,
                                     nil,
                                     row[:create_time],
                                     row[:created_by],
                                     row[:source_system])
        end
    end

    result
  end

end