Sequel.migration do

  up do
    # enum.name = runcorn_sensitivity_label
    # current values = [
    #  'atsi_cultural',
    #  'cultural_sensitivity',
    #  'distressing',
    #  'published',
    #  'secret_and_sacred',
    # ]
    #
    # replace with = [
    #  'This may contain information or photographs which some people may find distressing or offensive.'
    #  'This may contain terms or images which Aboriginal and Torres Strait Islander people may find distressing or offensive.'
    # ]
    enum_id = self[:enumeration][:name => 'runcorn_sensitivity_label'][:id]

    valid_value_ids = self[:enumeration_value]
                        .filter(:enumeration_id => enum_id)
                        .filter(:value => ['atsi_cultural', 'distressing'])
                        .select(:id)
                        .map{|row| row[:id]}

    self[:resource]
      .filter(Sequel.~(:sensitivity_label_id => nil))
      .filter(Sequel.~(:sensitivity_label_id => valid_value_ids))
      .update(:sensitivity_label_id => nil)

    self[:archival_object]
      .filter(Sequel.~(:sensitivity_label_id => nil))
      .filter(Sequel.~(:sensitivity_label_id => valid_value_ids))
      .update(:sensitivity_label_id => nil)

    self[:enumeration_value]
      .filter(:enumeration_id => enum_id)
      .filter(Sequel.~(:id => valid_value_ids))
      .delete

    self[:enumeration_value]
      .filter(:enumeration_id => enum_id)
      .filter(:value => 'atsi_cultural')
      .update(:value => 'This may contain terms or images which Aboriginal and Torres Strait Islander people may find distressing or offensive.')

    self[:enumeration_value]
      .filter(:enumeration_id => enum_id)
      .filter(:value => 'distressing')
      .update(:value => 'This may contain information or photographs which some people may find distressing or offensive.')

    self[:enumeration]
      .filter(:id => enum_id)
      .update(:editable => 0)
  end

end
