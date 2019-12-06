class AttachRAP < BatchActionHandler

  register(:attach_rap,
           'Attach a new RAP to all of the objects in the batch. ' +
           'Descendents of objects in the batch, that are not themselves in the batch, ' +
           'but which have their own attached RAP will not be affected.',
           [:archival_object, :physical_representation, :digital_representation])


  def self.default_params
    {
      'open_access_metadata' => true,
      'years' =>  nil,
      'access_category' => nil,
      'notes' => '',
      'notice_date' => '',
      'internal_reference' => '',
    }
  end


  def self.validate_params(params)
    begin
      JSONModel::JSONModel(:rap).from_hash(params)
    rescue JSONModel::ValidationException => e
      errs = e.errors.map{|fld, msgs| I18n.t('rap.' + fld) + ': ' + msgs.join('. ') }.join('; ')

      raise InvalidParams.new(errs)
    end
  end


  def self.process_form_params(params)
    params['open_access_metadata'] = params['open_access_metadata'] == '1' ? true : false

    params
  end

  def self.perform_action(params, user, action_uri, uris)
    validate_params(params)

    counts = {}

    out = "RAP attached to:\n"

    uris.map {|uri| {:uri => uri, :parsed => JSONModel.parse_reference(uri)}}
      .group_by {|parsed| parsed[:parsed].fetch(:type)}
      .each do |type, type_refs|

      model = ASModel.all_models.select{|m| m.table_name == type.intern}.first

      counts[type] = type_refs.length

      type_refs.each do | ref|
        RAP.attach_rap(model, ref[:parsed][:id], JSONModel::JSONModel(:rap).from_hash(params))
      end
    end

    out += counts.map{|model, count| "    #{I18n.t(model + '._singular')}: #{count}" }.join("\n")

    out += "\n\nNOTE: Any descendants not in the batch are unaffected if they already have a RAP attached."

    out
  end
end
