require 'db/migrations/utils'

Sequel.migration do

  up do
    create_table(:runcorn_job_status) do
      primary_key :id

      String :job_name, :unique => true
      DateTime :last_run_time
    end
  end

end
