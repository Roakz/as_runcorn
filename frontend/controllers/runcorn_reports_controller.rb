class RuncornReportsController < ApplicationController
  set_access_control "view_repository" => [:index, :generate_report]

  def index
  end

  def generate_report
    self.response.headers["Content-Type"] = 'text/csv'
    self.response.headers['Last-Modified'] = Time.now.ctime
    self.response.headers['Content-Disposition'] = "attachment; filename=\"#{params[:report]}.#{Date.today.iso8601}.csv\""

    case params[:report]
    when 'agency_loans_report'
      self.response_body = Enumerator.new do |stream|
        JSONModel::HTTP::stream('/runcorn_reports/file_issues_and_loans', {
          :date_from => params[:date_from],
          :date_to => params[:date_to],
        }) do |response|
          response.read_body do |chunk|
            stream << chunk
          end
        end
      end
    end
  end
end