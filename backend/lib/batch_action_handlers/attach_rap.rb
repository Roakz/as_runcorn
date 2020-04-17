class AttachRAP < BatchActionHandler

  register(:attach_rap,
           'Attach a new RAP to all of the objects in the batch. ' +
           'Descendents of objects in the batch, that are not themselves in the batch, ' +
           'but which have their own attached RAP will not be affected.',
           [:archival_object, :physical_representation, :digital_representation],
           :set_raps)


  def self.default_params
    {
      'open_access_metadata' => true,
      'years' =>  nil,
      'access_category' => '',
      'notes' => '',
      'notice_date' => '',
      'internal_reference' => '',
    }
  end


  def self.validate_params(params)
    @rap_closed_cats ||= AppConfig[:as_runcorn_forever_closed_access_categories]

    if @rap_closed_cats.include?(params['access_category']) || params['access_category'] === 'N/A'
      if params['years']
        raise InvalidParams.new('Years cannot have a value for permanently closed access categories')
      end
    elsif params['access_category'] === ''
      # no wuckahs
    else
      unless params['years']
        raise InvalidParams.new('Years must have a value: 0 for open; or 1 - 100 years')
      end
    end

    if params['access_category'] === 'N/A' && params['open_access_metadata']
        raise InvalidParams.new('Publish Details cannot be true if Access Category is N/A')
    end

    if params['years']
      years_i = params['years'].to_i
      unless params['years'] == years_i.to_s && years_i >= 0 && years_i <= 100
        raise InvalidParams.new('If years is set it must have a value from 0 to 100')
      end
    end

    begin
      JSONModel::JSONModel(:rap).from_hash(params)
    rescue JSONModel::ValidationException => e
      errs = e.errors.map{|fld, msgs| I18n.t('rap.' + fld) + ': ' + msgs.join('. ') }.join('; ')

      raise InvalidParams.new(errs)
    end
  end


  def self.process_form_params(params)
    params['open_access_metadata'] = params['open_access_metadata'] == '1' ? true : false
    params['years'] = nil if params['years'].empty?

    params
  end

  def self.perform_action(params, user, action_uri, uris)
    validate_params(params)

    counts = {}

    rap = JSONModel::JSONModel(:rap).from_hash(params)

    out = "RAP attached to:\n"

    RAP.with_deferred_propagations do
      uris.map {|uri| {:uri => uri, :parsed => JSONModel.parse_reference(uri)}}
        .group_by {|parsed| parsed[:parsed].fetch(:type)}
        .each do |type, type_refs|

        model = ASModel.all_models.select{|m| m.table_name == type.intern}.first

        counts[type] = type_refs.length
        type_refs.each do | ref|
          RAP.attach_rap(model, ref[:parsed][:id], rap)
        end
      end
    end

    out += counts.map{|model, count| "    #{I18n.t(model + '._singular')}: #{count}" }.join("\n")

    out += "\n\nNOTE: Any descendants not in the batch are unaffected if they already have a RAP attached."

    out
  end
end
