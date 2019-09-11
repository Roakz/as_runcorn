class RapExpirationJob

  JOB_NAME = "RapExpirationJob"
  RANDOM_WAIT_MAX_SECONDS = 300


  def self.call
    now = Time.now

    # FIXME
    # sleep rand(RANDOM_WAIT_MAX_SECONDS)

    DB.open do |db|
      status = db[:runcorn_job_status].filter(:job_name => JOB_NAME).first
      last_run_time = if status
                        status[:last_run_time]
                      else
                        Time.at(0)
                      end

      if (Time.now - last_run_time) >= (Integer(AppConfig[:rap_expiration_minutes]) * 60)
        # Archival Objects with RAPs applied
        ao_ids = db["select ao.id" +
                    " from rap_applied ra" +
                    " inner join rap on ra.is_active = 1" +
                    " AND rap.id = ra.rap_id" +
                    " AND rap.years is not null" +
                    " inner join archival_object ao on ao.id = ra.archival_object_id" +
                    " inner join date on date.archival_object_id = ao.id" +
                    " AND date.end is not null" +
                    " where DATE_ADD(date(substring(concat(date.end, '-12-31'), 1, 10)), interval rap.years year) <= DATE('%s')" % [now.strftime('%Y-%m-%d')] +
                    "   AND DATE_ADD(date(substring(concat(date.end, '-12-31'), 1, 10)), interval rap.years year) >= DATE('%s')" % [last_run_time.strftime('%Y-%m-%d')]
                   ].map {|row| row[:id]}

        # Representations with RAPs applied have their attached Archival Object reindexed too
        ['physical_representation', 'digital_representation'].each do |representation|
          ao_ids += db["select ao.id" +
                       " from rap_applied ra" +
                       " inner join rap on ra.is_active = 1" +
                       " AND rap.id = ra.rap_id" +
                       " AND rap.years is not null" +
                       " inner join #{representation} rep on rep.id = ra.#{representation}_id" +
                       " inner join archival_object ao on ao.id = rep.archival_object_id" +
                         " inner join date on date.archival_object_id = ao.id AND date.end is not null" +
                         " where DATE_ADD(date(substring(concat(date.end, '-12-31'), 1, 10)), interval rap.years year) <= DATE('%s')" % [now.strftime('%Y-%m-%d')] +
                         "   AND DATE_ADD(date(substring(concat(date.end, '-12-31'), 1, 10)), interval rap.years year) >= DATE('%s')" % [last_run_time.strftime('%Y-%m-%d')]
                      ].map {|row| row[:id]}
        end

        ao_ids.uniq!

        Log.info("#{self} marking #{ao_ids.length} records for reindexing")

        db[:archival_object].filter(:id => ao_ids).update(:system_mtime => now)




        db[:runcorn_job_status].delete
        db[:runcorn_job_status].insert(:job_name => JOB_NAME, :last_run_time => now)
      end
    end
  end

end
