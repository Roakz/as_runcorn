class ArchivesSpaceService < Sinatra::Base
  Endpoint.post('/repositories/:repo_id/bulk_record_changes')
    .description("FIXME")
    .params(["repo_id", :repo_id])
    .use_transaction(false)
    .permissions([])
    .returns([200, :updated]) \
  do
    begin
      RequestContext.open(:current_username => 'admin') do
        DB.open do
          BulkRecordChanges.run(File.join(File.dirname(__FILE__), "../../sample_bulk_edit.xlsx"))
        end
      end

      json_response({})
    rescue BulkRecordChanges::BulkUpdateFailed => errors
      json_response(errors.to_json)
    end
  end
end
