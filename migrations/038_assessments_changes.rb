require 'db/migrations/utils'

Sequel.migration do

  up do
    alter_table(:assessment_rlshp) do
      add_column(:physical_representation_id, :integer,  :null => true)
      add_foreign_key([:physical_representation_id], :physical_representation, :key => :id, :name => 'assessment_physrep_fk')
    end

    alter_table(:external_id) do
      add_column(:assessment_id, :integer,  :null => true)
      add_foreign_key([:assessment_id], :assessment, :key => :id, :name => 'assessment_external_id_fk')
    end

    create_enum('runcorn_treatment_priority', ['LOW', 'MEDIUM', 'HIGH'])

    alter_table(:assessment) do
      add_column(:treatment_priority_id, Integer, :null => true)
      add_foreign_key([:treatment_priority_id], :enumeration_value, :key => :id, :name => 'assessment_treatment_priority_fk')
    end

    # reusing the 'format' type because it isn't required by qsa and it turns out
    # adding a new type requires hacking around inside the Assessment model
    self[:assessment_attribute_definition].filter(:type => 'format').delete

    [
     'A good wash',
     'Try blowing on it',
     'Drink glass of water upsidedown',
    ].each_with_index do |treatment, ix|
      self[:assessment_attribute_definition].insert(:repo_id => 1, :label => treatment, :type => 'format', :position => ix)
    end
  end

  down do
  end
end
