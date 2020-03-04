require 'db/migrations/utils'

Sequel.migration do

  up do
    subject_source_enum_id = self[:enumeration].filter(:name => 'subject_source').get(:id)
    term_type_enum_id = self[:enumeration].filter(:name => 'subject_term_type').get(:id)

    self[:subject_term].delete
    self[:term].delete
    self[:subject].delete
    self[:enumeration_value].filter(:enumeration_id => subject_source_enum_id).delete
    self[:enumeration_value].filter(:enumeration_id => term_type_enum_id).delete

    %w(aat agift hr lcsh lcgh1 lcgh2 nla qgaz qsa slq lc_graphic).each do |enum_value|
      pos = (self[:enumeration_value].filter(:enumeration_id => subject_source_enum_id).max(:position) || 0) + 1
      self[:enumeration_value].insert({:enumeration_id => subject_source_enum_id, :value => enum_value, :position => pos})
    end

    %w(geographical_name record_type subject temporal genre).each do |enum_value|
      pos = (self[:enumeration_value].filter(:enumeration_id => term_type_enum_id).max(:position) || 0) + 1
      self[:enumeration_value].insert({:enumeration_id => term_type_enum_id, :value => enum_value, :position => pos})
    end

  end
end
