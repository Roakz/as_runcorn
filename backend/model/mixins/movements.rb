module Movements

  def self.included(base)
    base.extend(ClassMethods)

    base.one_to_many :movement
    base.def_nested_record(:the_property => :movements,
                           :contains_records_of_type => :movement,
                           :corresponding_to_association => :movement)
  end


  def move(opts)
    json = self.class.to_jsonmodel(self)

    mvmt = {
      'user' => opts[:user],
      'move_date' => opts.fetch(:date, Time.now),
    }

    mvmt['context_uri'] = opts[:context] if opts[:context]

    if (opts[:location])
      if (loc = JSONModel.parse_reference(opts[:location]))
        mvmt['storage_location'] = {'ref' => opts[:location]}
      else
        mvmt['functional_location'] = opts[:location]
      end
    else
      mvmt['functional_location'] = 'HOME'
    end

    json['movements'].push(mvmt)

    self.update_from_json(json)
  end


  def update_from_json(json, opts = {}, apply_nested_records = true)
    self.class.check_move_to_storage(json)
    self.class.set_current_to_last_move!(json)
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


    def check_move_to_storage(json)
      unless @move_to_storage_permitted
        errors = {}

        json['movements'].each_with_index do |move, ix|
          next unless move['storage_location']
          errors["movements/#{ix}/storage_location"] = ["Cannot move to a storage location"]
        end

        unless errors.empty?
          raise JSONModel::ValidationException.new(:errors => errors)
        end
      end
    end
  end
end
