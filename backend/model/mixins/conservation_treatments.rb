module ConservationTreatments

  def self.included(base)
    base.one_to_many :conservation_treatment

    base.def_nested_record(:the_property => :conservation_treatments,
                           :contains_records_of_type => :conservation_treatment,
                           :corresponding_to_association  => :conservation_treatment)
  end

end
