module ExternalResources

  def self.included(base)
    base.one_to_many(:external_resource)

    base.def_nested_record(:the_property => :external_resources,
                           :contains_records_of_type => :external_resource,
                           :corresponding_to_association  => :external_resource)
  end

end
