class FunctionalMove < BatchActionHandler

  register(:functional_move,
           'Create a movement to a new functional location.',
           [:top_container, :physical_representation])


  def self.default_params
    {
      'location' => 'HOME'
    }
  end


  def self.validate_params(params)
    location = params['location'] or raise InvalidParams.new('Must provide a location')

    locs = BackendEnumSource.values_for('runcorn_location')
    unless locs.include?(location)
      raise InvalidParams.new('location must be one of: ' + locs.join(', '))
    end
  end


  def self.perform_action(params, user, action_uri, uris)
    validate_params(params)

    user_uri = JSONModel::JSONModel(:agent_person).uri_for(User.filter(:username => user).get(:agent_record_id))

    opts = {
      :user => user_uri,
      :location => params['location'],
      :context => action_uri,
    }

    models = ASModel.all_models.select {|model| model.included_modules.include?(Movements)}

    begin
      uris.each do |uri|
        ref = JSONModel.parse_reference(uri)
        model = models.select{|model| model.my_jsonmodel.record_type == ref[:type]}.first
        model[ref[:id]].move(opts)
      end
    rescue => e
      # FIXME: think about exception handling
      raise e
    end
  end
end
