class BulkChangesController < ApplicationController

  set_access_control "create_batch" => [:index, :new, :download_template, :run, :show, :download_file]

  def index
    recent_jobs = JSONModel::HTTP.get_json("/repositories/#{session[:repo_id]}/bulk_record_changes/recent")

    @recent_jobs = recent_jobs.map {|json|
      job_info = json.fetch('job', '{}')

      summary = if job_info.include?('added') && job_info.include?('updated')
        "%d record(s) added; %d record(s) updated" % [job_info['added'], job_info['updated']]
      else
        "-"
      end

      {
        'owner' => json.fetch('owner'),
        'status' => json.fetch('status'),
        'time_submitted' => Time.at(Time.parse(json.fetch('time_submitted')).to_i).strftime('%d/%m/%Y %H:%M:%S'),
        'id' => JSONModel.parse_reference(json.fetch('uri'))[:id],
        'summary' => summary,
      }
    }
  end

  def new
  end

  def show
    @job = JSONModel(:job).find(params[:id], "resolve[]" => "repository")
    @files = JSONModel::HTTP::get_json("#{@job['uri']}/output_files") 
  end

  def current_record
    @job
  end

  def download_file
    @job = JSONModel(:job).find(params[:job_id], "resolve[]" => "repository")

    self.response.headers["Content-Type"] = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
    self.response.headers["Content-Disposition"] = "attachment; filename=\"job_#{params[:job_id].to_s}.xlsx\""
    self.response.headers['Last-Modified'] = Time.now.ctime

    self.response_body = Enumerator.new do |stream|
      JSONModel::HTTP.stream("/repositories/#{JSONModel::repository}/jobs/#{params[:job_id]}/output_files/#{params[:id]}") do |response|
        response.read_body do |chunk|
          stream << chunk
        end
      end
    end
  end

  def download_template
    self.response.headers["Content-Type"] = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
    self.response.headers["Content-Disposition"] = "attachment; filename=\"bulk_record_changes_#{Date.today.iso8601}.xlsx\""
    self.response.headers['Last-Modified'] = Time.now.ctime

    self.response_body = Enumerator.new do |stream|
      JSONModel::HTTP.stream("/repositories/#{session[:repo_id]}/bulk_record_changes/download_template") do |response|
        response.read_body do |chunk|
          stream << chunk
        end
      end
    end
  end

  def run
    response = JSONModel::HTTP.post_form("/repositories/#{session[:repo_id]}/bulk_record_changes",
                                         {
                                           :file => UploadIO.new(params[:import_data].tempfile,
                                                                 params[:import_data].content_type,
                                                                 params[:import_data].original_filename),
                                         },
                                         :multipart_form_data)

    json = ASUtils.json_parse(response.body)
    uri = json['job']

    redirect_to :action => :show, :id => JSONModel.parse_reference(uri)[:id]
  end

end
