require 'db/migrations/utils'

Sequel.migration do

  up do
    alter_table(:sub_container) do
      drop_constraint(:sub_container_physrep_id_fk, :type => :foreign_key)
      drop_column(:physical_representation_id)
    end

    create_table(:representation_container_rlshp) do
      primary_key :id

      Integer :physical_representation_id, :null => false
      Integer :top_container_id, :null => false
      Integer :aspace_relationship_position, :default => 0

      apply_mtime_columns(false)
    end

    alter_table(:representation_container_rlshp) do
      add_foreign_key([:physical_representation_id], :physical_representation, :key => :id)
      add_foreign_key([:top_container_id], :top_container, :key => :id)
    end

    self.transaction do
      # For want of a better idea, we'll link all existing representations to
      # whatever top container comes to hand.
      self[:repository].select(:id).each do |row|
        repo_id = row[:id]

        top_containers = self[:top_container].filter(:repo_id => repo_id).select(:id).map {|row| row[:id]}

        unless top_containers.empty?
          self[:physical_representation].filter(:repo_id => repo_id).select(:id).map {|row| row[:id]}.each do |phys_rep_id|
            # whee!
            self[:representation_container_rlshp].insert(:physical_representation_id => phys_rep_id,
                                                         :top_container_id => top_containers.sample,
                                                         :aspace_relationship_position => 0,
                                                         :system_mtime => Time.now,
                                                         :user_mtime => Time.now)
          end
        end
      end
    end
  end

end
