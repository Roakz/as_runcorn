module Movements

  def self.included(base)
    base.extend(ClassMethods)

    base.one_to_many :movement
    base.def_nested_record(:the_property => :movements,
                           :contains_records_of_type => :movement,
                           :corresponding_to_association => :movement)
  end


  def update_from_json(json, opts = {}, apply_nested_records = true)
    self.set_current_to_last_move!(json)
    super
  end


  module ClassMethods
    def create_from_json(json, opts = {})
      set_current_to_last_move!(json)
      super
    end

    def set_current_to_last_move!(json)
      # sort movements by move_date and
      # set the current location to the value in the most
      # recent move to a functional location if there is one
      unless json['movements'].empty?
        json['movements'] = json['movements'].sort{|a,b| b['move_date'] <=> a['move_date']}
        last_fn_loc = json['movements'].select{|m| m['functional_location']}.first
        json['current_location'] = last_fn_loc['functional_location'] if last_fn_loc
      end
    end

  end
end
