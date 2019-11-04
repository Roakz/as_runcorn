require 'db/migrations/utils'

Sequel.migration do

  up do
    drop_table(:runcorn_job_status)
  end

end
