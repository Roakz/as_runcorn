class BulkChangeJob < JobRunner

  register_for_job_type('bulk_change_job',
                        :create_permissions => :create_batch,
                        :cancel_permissions => :administer_system)

  def run
    job = @job

    job.write_output("Starting bulk create/update job\n")

    job.job_files.each do |input_file|
      begin
        RequestContext.open(:current_username => job.owner.username,
                            :repo_id => job.repo_id) do
          DB.open(true) do
            summary = BulkRecordChanges.run(input_file.file_path, job)

            job.write_output("\nSuccess!  %d record(s) were created; %d record(s) were updated" % [
                                summary[:added],
                                summary[:updated]
                              ])

            job.job_blob = ASUtils.to_json(summary)
            job.save

            job.finish!(:completed)
            self.success!
          end
        end
      rescue BulkRecordChanges::BulkUpdateFailed => e
        job.write_output("Errors encountered during processing\n\n")

        e.errors.each_with_index do |error, idx|
          if idx > 0
            job.write_output("\n")
          end

          # Indented lines
          formatted_errors = error.fetch(:errors).join("\n        ")

          job.write_output("Sheet name: #{error.fetch(:sheet)}")
          job.write_output("Row number: #{error.fetch(:row)}")
          job.write_output("Column: #{error.fetch(:column)}")
          job.write_output("Errors: " + formatted_errors)
        end

        job.finish!(:failed)
      rescue => e
        Log.exception(e)
        job.write_output("Unexpected failure while running job.  Error: #{e}")

        job.finish!(:failed)
        raise e
      end
    end
  end
end
