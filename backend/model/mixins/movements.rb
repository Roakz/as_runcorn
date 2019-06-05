module Movements

  def self.included(base)
    base.one_to_many :movement
    base.def_nested_record(:the_property => :movements,
                           :contains_records_of_type => :movement,
                           :corresponding_to_association => :movement)
  end

end
