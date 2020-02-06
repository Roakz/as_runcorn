require 'db/migrations/utils'

Sequel.migration do

  up do
    create_table(:conservation_treatment_applied_treatment) do
      primary_key :id

      foreign_key :conservation_treatment_id, :conservation_treatment, :null => false
      foreign_key :assessment_attribute_definition_id, :assessment_attribute_definition, :null => false

      Integer :aspace_relationship_position

      apply_mtime_columns(false)
    end

    treatments_map = self[:assessment_attribute_definition]
                      .filter(:repo_id => [1,2])
                      .filter(:type => 'format')
                      .select(:id, :label)
                      .map {|row| [row[:label].downcase, row[:id]]}.to_h

    self[:conservation_treatment]
      .filter(Sequel.~(:treatments_applied => nil))
      .select(:id, :treatments_applied)
      .all
      .each do |row|
      treatments = row[:treatments_applied].split(',').map{|s| s.downcase.strip}.reject{|s| s.empty?}
      treatments.each do |treatment|
        if treatments_map.include?(treatment)
          self[:conservation_treatment_applied_treatment]
            .insert(:conservation_treatment_id => row[:id],
                    :assessment_attribute_definition_id => treatments_map.fetch(treatment),
                    :created_by => 'admin',
                    :last_modified_by => 'admin',
                    :system_mtime => Time.now,
                    :user_mtime => Time.now)
        end
      end
    end

    alter_table(:conservation_treatment) do
      drop_column(:treatments_applied)
      add_column(:persistent_create_time, DateTime, :null => true)
    end

    self[:conservation_treatment]
      .update(:persistent_create_time => :create_time)

    alter_table(:conservation_treatment) do
      set_column_not_null(:persistent_create_time)
    end
  end
end
