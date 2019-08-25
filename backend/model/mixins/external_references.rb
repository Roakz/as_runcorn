module ExternalReferences

  def self.included(base)
    base.one_to_many(:external_reference)

    base.def_nested_record(:the_property => :external_references,
                           :contains_records_of_type => :external_reference,
                           :corresponding_to_association  => :external_reference)
  end

end
