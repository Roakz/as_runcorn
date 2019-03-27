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
