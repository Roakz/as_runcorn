require 'db/migrations/utils'

Sequel.migration do

  up do
    create_table(:movement_user_rlshp) do
      primary_key :id

      Integer :movement_id
      Integer :agent_person_id

      Integer :suppressed, :default => 0
      Integer :aspace_relationship_position

      apply_mtime_columns(false)
    end

    alter_table(:movement_user_rlshp) do
      add_foreign_key([:movement_id], :movement, :key => :id)
      add_foreign_key([:agent_person_id], :agent_person, :key => :id)
    end

    # create a rlshp entry for each existing movement using its created_by
    puts "Creating user relationships for movements ..."
    self[:movement].each do |mvmt|
      person_id = self[:user].filter(:username => mvmt[:created_by]).first[:agent_record_id]
      puts "Movement: #{mvmt[:id]}, User: #{mvmt[:created_by]}, person_id: #{person_id}"
      self[:movement_user_rlshp].insert(:movement_id => mvmt[:id],
                                        :agent_person_id => person_id,
                                        :aspace_relationship_position => 0,
                                        :system_mtime => Time.now,
                                        :user_mtime => Time.now)
    end

    # and drop the now defunct user column
    alter_table(:movement) do
      drop_column(:user)
    end
  end

  down do
  end

end
