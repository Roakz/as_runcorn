class ArchivesSpaceService < Sinatra::Base

  Endpoint.get_or_post('/runcorn_reports/file_issues_and_loans')
    .description("Report on File Issue Requests & loans to Agencies")
    .params(["from_date", String, "From date in range", :optional => true],
            ["to_date", String, "To date in range", :optional => true])
    .permissions([]) # FIXME
    .returns([200, "(:csv)"]) \
  do
    [
      200,
      {
        "Content-Type" => "text/csv",
        "Content-Disposition" => "attachment; filename=\"file_issues_and_loans.#{Date.today.iso8601}.csv\""
      },
      AgencyLoansReport.new(DateParse.date_parse_down(params[:from_date]), DateParse.date_parse_up(params[:to_date])).to_stream
    ]
  end

  Endpoint.get_or_post('/runcorn_reports/transfers')
    .description("Report on Agency Transfers")
    .params(["from_date", String, "From date in range", :optional => true],
            ["to_date", String, "To date in range", :optional => true])
    .permissions([]) # FIXME
    .returns([200, "(:csv)"]) \
  do
    [
      200,
      {
        "Content-Type" => "text/csv",
        "Content-Disposition" => "attachment; filename=\"transfers.#{Date.today.iso8601}.csv\""
      },
      AgencyTransfersReport.new(DateParse.date_parse_down(params[:from_date]), DateParse.date_parse_up(params[:to_date])).to_stream
    ]
  end

  Endpoint.get_or_post('/runcorn_reports/transfer_proposals')
    .description("Report on Agency Transfer Proposals")
    .params(["from_date", String, "From date in range", :optional => true],
            ["to_date", String, "To date in range", :optional => true])
    .permissions([]) # FIXME
    .returns([200, "(:csv)"]) \
  do
    [
      200,
      {
        "Content-Type" => "text/csv",
        "Content-Disposition" => "attachment; filename=\"transfer_proposals.#{Date.today.iso8601}.csv\""
      },
      AgencyTransferProposalsReport.new(DateParse.date_parse_down(params[:from_date]), DateParse.date_parse_up(params[:to_date])).to_stream
    ]
  end

  Endpoint.get_or_post('/runcorn_reports/file_issue_invoices')
    .description("Produce invoice for file issues")
    .params(["from_date", String, "From date in range", :optional => true],
            ["to_date", String, "To date in range", :optional => true],
            ["agency_ref", String, "URI of agent_corporate_entity", :optional => true],
            ["location_id", Integer, "ID of location", :optional => true])
    .permissions([]) # FIXME
    .returns([200, "(:pdf)"]) \
  do
    path = FileIssueInvoice.new(params).to_file

    stream = Enumerator.new do |y|
      begin
        File.open(path, 'rb') do |fh|
          while (chunk = fh.read(4096)) != nil
            y << chunk
          end
        end
      ensure
        File.unlink(path)
      end
    end


    [
      200,
      {
        "Content-Type" => "application/pdf",
        "Content-Disposition" => "attachment; filename=\"file_issue_invoice.#{Date.today.iso8601}.pdf\""
      },
      stream
    ]
  end

  Endpoint.get('/runcorn_reports/locations_for_agency')
    .description("Locations for an agency")
    .params(["agency_ref", String, "URI of agent_corporate_entity"])
    .permissions([]) # FIXME
    .returns([200, "(:json)"]) \
  do
    agency_id = JSONModel.parse_reference(params[:agency_ref]).fetch(:id)
    agency = AgentCorporateEntity.get_or_die(agency_id)
    json_response(agency.fetch_map_agency_locations)
  end
end
