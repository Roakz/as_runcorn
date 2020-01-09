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

end