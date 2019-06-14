require 'pp'

module Movements

  @@models = []

  def self.included(base)
    base.extend(ClassMethods)

    base.one_to_many :movement
    base.def_nested_record(:the_property => :movements,
                           :contains_records_of_type => :movement,
                           :corresponding_to_association => :movement)

    @@models << base
  end


  def self.models
    @@models
  end


  def move(opts)
    json = self.class.to_jsonmodel(self)

    mvmt = {
      'user' => opts[:user],
      'move_date' => opts.fetch(:date, Time.now.getlocal.iso8601),
    }

    mvmt['move_context'] = {'ref' => opts[:context]} if opts[:context]

    if (opts[:location])
      if (loc = JSONModel.parse_reference(opts[:location]))
        mvmt['storage_location'] = {'ref' => opts[:location]}
      else
        mvmt['functional_location'] = opts[:location]
      end
    else
      mvmt['functional_location'] = 'HOME'
    end

    # if replacing, remove any movements with the same context and location
    if (opts[:replace] || opts[:remove]) && mvmt['move_context']
      json['movements'] = json['movements'].select do |m|
        same_context = m['move_context'] && m['move_context']['ref'] == mvmt['move_context']['ref']
        same_location = m['functional_location'] && m['functional_location'] == mvmt['functional_location']
        same_location ||= m['storage_location'] && mvmt['storage_location'] && m['storage_location']['ref'] == mvmt['storage_location']['ref']

        ! (same_context && same_location)
      end
    end

    json['movements'].push(mvmt) unless opts[:remove]

    self.update_from_json(json)
  end


  def update_from_json(json, opts = {}, apply_nested_records = true)
    self.class.check_move_to_storage(json)
    self.class.set_current_to_last_move!(json)

    super
  end


  module ClassMethods
    def sort_movements(mvmts)
        mvmts.sort{|a,b| b['move_date'] <=> a['move_date']}
    end


    def create_from_json(json, opts = {})
      check_move_to_storage(json)
      set_current_to_last_move!(json)
      super
    end


    def sequel_to_jsonmodel(objs, opts = {})
      jsons = super

      objs.zip(jsons).each do |obj, json|
        json['movements'] = sort_movements(json['movements'])
      end

      jsons
    end


    def set_current_to_last_move!(json)
      # sort movements by move_date and
      # set the current location to the value in the most
      # recent move to a functional location if there is one
      unless json['movements'].empty?
        json['movements'] = sort_movements(json['movements'])
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
