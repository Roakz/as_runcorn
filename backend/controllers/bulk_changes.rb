require 'pp'

class ArchivesSpaceService < Sinatra::Base
  Endpoint.get('/repositories/:repo_id/bulk_record_changes/download_template')
    .description("Download the bulk record changes Excel template")
    .params(["repo_id", :repo_id])
    .permissions([:create_batch])
    .returns([200, :xlsx]) \
  do
    send_file(File.join(File.dirname(__FILE__), '..', '..', 'bulk_edit_template.xlsx'))
  end


  Endpoint.get('/repositories/:repo_id/bulk_record_changes/recent')
    .description("Download the bulk record changes Excel template")
    .params(["repo_id", :repo_id])
    .permissions([:create_batch])
    .returns([200, :jobs]) \
  do
    objs = Job.filter(:job_type => 'bulk_change_job')
             .order(Sequel.desc(:id))
             .limit(20)
             .all
    jsons = Job.sequel_to_jsonmodel(objs)

    objs.zip(jsons).each do |obj, json|
      json['job'] = ASUtils.json_parse(json.job_blob)
    end

    json_response(jsons)
  end

  Endpoint.post('/repositories/:repo_id/bulk_record_changes')
    .description("Apply a set of record creates/updates from an Excel spreadsheet")
    .params(["repo_id", :repo_id],
            ["file", UploadFile, "The Excel spreadsheet"])
    .use_transaction(false)
    .permissions([:create_batch])
    .returns([200, "job created"]) \
  do
    job = Job.create_from_json(JSONModel(:job).from_hash(
                                 'job_type' => 'bulk_change_job',
                                 'jsonmodel_type' => 'job',
                                 "job" => {
                                   "jsonmodel_type" => "bulk_change_job",
                                 }
                               ),
                               :user => current_user)

    job.add_file(params[:file].tempfile)

    json_response(:status => "submitted", :job => job.uri)
  end
end
