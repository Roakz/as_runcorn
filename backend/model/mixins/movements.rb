module Movements

  def self.included(base)
    base.extend(ClassMethods)

    base.one_to_many :movement
    base.def_nested_record(:the_property => :movements,
                           :contains_records_of_type => :movement,
                           :corresponding_to_association => :movement)
  end


  def update_from_json(json, opts = {}, apply_nested_records = true)
    self.check_move_to_storage(json)
    self.set_current_to_last_move!(json)
    super
  end


  module ClassMethods
    def create_from_json(json, opts = {})
      check_move_to_storage(json)
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

    def move_to_storage_permitted
      @move_to_storage_permitted = true
    end


    # FIXME: can this be done in a more standard way?
    # FIXME: and if not then the error should reference the movement properly
    def check_move_to_storage(json)
      unless @move_to_storage_permitted
        moves_to_storage = json['movements'].select{|m| m['storage_location']}
        unless moves_to_storage.empty?
          raise JSONModel::ValidationException.new(:errors => {:movements => ["Cannot move to a storage location"]})
        end
      end
    end
  end
end
