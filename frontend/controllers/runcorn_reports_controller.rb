class RuncornReportsController < ApplicationController
  set_access_control "view_repository" => [:index, :generate_report, :locations_for_agency]

  def index
  end

  def generate_report
    self.response.headers["Content-Type"] = 'text/csv'
    self.response.headers['Last-Modified'] = Time.now.ctime
    self.response.headers['Content-Disposition'] = "attachment; filename=\"#{params[:report]}.#{Date.today.iso8601}.csv\""

    case params[:report]
    when 'agency_loans_report'
      self.response.headers['Content-Disposition'] = "attachment; filename=\"File Issue Statistics #{Date.today.iso8601}.csv\""
      self.response_body = Enumerator.new do |stream|
        JSONModel::HTTP::stream('/runcorn_reports/file_issues_and_loans', {
          :from_date => params[:from_date],
          :to_date => params[:to_date],
        }) do |response|
          response.read_body do |chunk|
            stream << chunk
          end
        end
      end
    when 'agency_transfers_report'
      self.response_body = Enumerator.new do |stream|
        JSONModel::HTTP::stream('/runcorn_reports/transfers', {
          :from_date => params[:from_date],
          :to_date => params[:to_date],
        }) do |response|
          response.read_body do |chunk|
            stream << chunk
          end
        end
      end
    when 'agency_transfer_proposals_report'
      self.response_body = Enumerator.new do |stream|
        JSONModel::HTTP::stream('/runcorn_reports/transfer_proposals', {
          :from_date => params[:from_date],
          :to_date => params[:to_date],
        }) do |response|
          response.read_body do |chunk|
            stream << chunk
          end
        end
      end
    when 'file_issue_invoices'
      self.response.headers["Content-Type"] = 'text/pdf'
      self.response.headers['Content-Disposition'] = "attachment; filename=\"#{params[:report]}.#{Date.today.iso8601}.pdf\""
      self.response_body = Enumerator.new do |stream|
        JSONModel::HTTP::stream('/runcorn_reports/file_issue_invoices', {
          :agency_ref => params[:agency_ref].blank? ? nil : params[:agency_ref],
          :location_id => params[:location_id].blank? ? nil : params[:location_id],
          :from_date => params[:from_date],
          :to_date => params[:to_date],
        }) do |response|
          response.read_body do |chunk|
            stream << chunk
          end
        end
      end
    when 'archives_search_user_activity'
      self.response_body = Enumerator.new do |stream|
        JSONModel::HTTP::stream('/runcorn_reports/archives_search_user_activity', {
          :from_date => params[:from_date],
          :to_date => params[:to_date],
        }) do |response|
          response.read_body do |chunk|
            stream << chunk
          end
        end
      end
    when 'assessments_report'
      self.response_body = Enumerator.new do |stream|
        JSONModel::HTTP::stream('/runcorn_reports/assessments', {
          :from_date => params[:from_date],
          :to_date => params[:to_date],
        }) do |response|
          response.read_body do |chunk|
            stream << chunk
          end
        end
      end
    when 'conservation_requests_report'
      self.response_body = Enumerator.new do |stream|
        JSONModel::HTTP::stream('/runcorn_reports/conservation_requests', {
          :from_date => params[:from_date],
          :to_date => params[:to_date],
        }) do |response|
          response.read_body do |chunk|
            stream << chunk
          end
        end
      end
    when 'conservation_treatments_report'
      self.response_body = Enumerator.new do |stream|
        JSONModel::HTTP::stream('/runcorn_reports/conservation_treatments', {
          :from_date => params[:from_date],
          :to_date => params[:to_date],
        }) do |response|
          response.read_body do |chunk|
            stream << chunk
          end
        end
      end
    else
      raise "Report not supported: #{params[:report]}"
    end
  end

  def locations_for_agency
    locations = JSONModel::HTTP::get_json('/runcorn_reports/locations_for_agency', {'agency_ref' => params[:agency_ref]})
    render :json => locations
  end
end
