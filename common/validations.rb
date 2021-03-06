# Override the built-in check date to deny the existence of "expression".
# Instead just require either begin or end to be set for a date to be valid
# (plus the usual requirement that begin falls before end.)
#
JSONModel.custom_validations['check_date'] = proc do |hash|
  errors = []

  if hash["begin"].nil?
    errors << ["begin", "missing_required_property"]
  else
    begin
      begin_date = JSONModel::Validations.parse_sloppy_date(hash['begin']) if hash['begin']
    rescue ArgumentError => e
      errors << ["begin", "not a valid date"]
    end

    begin
      if hash['end']
        # If padding our end date with months/days would cause it to fall before
        # the start date (e.g. if the start date was '2000-05' and the end date
        # just '2000'), use the start date in place of end.
        end_s = if begin_date && hash['begin'] && hash['begin'].start_with?(hash['end'])
                  hash['begin']
                else
                  hash['end']
                end

        end_date = JSONModel::Validations.parse_sloppy_date(end_s)
      end
    rescue ArgumentError
      errors << ["end", "not a valid date"]
    end

    if begin_date && end_date && end_date < begin_date
      errors << ["end", "must not be before begin"]
    end
  end


  errors

end

# And add some new validations
module JSONModel
  module Validations
    def self.check_movement_location(hash)
      errors = []
      if hash.fetch('move_to_storage_permitted', true)
        if hash['functional_location'] && hash['storage_location']
          errors << ['functional_location', 'Cannot have a value if a storage location is specified']
          errors << ['storage_location', 'Cannot have a value if a functional location is specified']
        end

        if !hash['functional_location'] && !hash['storage_location']
          errors << ['functional_location', 'Must have a value if a storage location is not specified']
          errors << ['storage_location', 'Must have a value if a functional location is not specified']
        end
      else
        unless hash['functional_location']
          errors << ['functional_location', 'Location must be specified']
        end
      end

      errors
    end

    if JSONModel(:movement)
      JSONModel(:movement).add_validation("check_movement_location") do |hash|
        check_movement_location(hash)
      end
    end


    def self.check_physical_representation_container(hash)
      errors = []

      unless hash['deaccessioned'] || ASUtils.wrap(hash['deaccessions']).length > 0
        unless hash['container'] && hash['container']['ref']
          errors << ['container', 'is required']
        end
      end

      errors
    end

    if JSONModel(:physical_representation)
      JSONModel(:physical_representation).add_validation("check_physical_representation_container") do |hash|
        check_physical_representation_container(hash)
      end
    end

    def self.check_rap_years(hash)
      errors = []
      # years can be null or 0 - 100
      if hash['years']
        begin
          years = Integer(hash['years'])
          if years < 0 || years > 100
            errors << ['years', 'must be in range 0-100 inclusive']
          end
        rescue ArgumentError
          errors << ['years', 'must be an integer']
        end
      end
      errors
    end

    if JSONModel(:rap)
      JSONModel(:rap).add_validation("check_rap_years") do |hash|
        check_rap_years(hash)
      end
    end

  end
end
