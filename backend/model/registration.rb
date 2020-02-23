class Registration

  ACTION_STATES = {
    :submit => :submitted,
    :withdraw => :draft,
    :approve => :approved
  }

  def self.response(obj, action, message)
    out = {
      :message => message,
      :action => action,
      :state => obj.registration_state,
    }

    if obj.registration_last_action
      out[:last_action] = {
        :action => obj.registration_last_action,
        :user => obj.registration_last_user,
        :time => obj.registration_last_time.getlocal,
      }
    end

    out
  end


  def self.handle_action(obj, action)
    if obj.registration_state.intern == ACTION_STATES[action]
      return response(obj, action, "Already #{ACTION_STATES[action]}. No change.")
    end

    if obj.registration_state.intern == :draft && action == :approve
      return response(obj, action, "Can't approve a draft. Please submit first. No change.")
    end

    user = RequestContext.get(:current_username)
    time = Time.now

    obj.update(:registration_state => ACTION_STATES[action].to_s,
               :registration_last_action => action.to_s,
               :registration_last_user => user,
               :registration_last_time => time,
               :publish => 0,
               :user_mtime => time,
               :last_modified_by => user)

    response(obj, action, "Success")
  end


  def self.submit(obj)
    handle_action(obj, :submit)
  end


  def self.withdraw(obj)
    handle_action(obj, :withdraw)
  end


  def self.approve(obj)
    handle_action(obj, :approve)
  end


  def self.list(model, state = :draft)
    ds = model.filter(:registration_state => state.to_s).reverse(:user_mtime)

    # just show the last 20 approved records
    # because this is the state at the end of the workflow
    ds = ds.limit(20) if state == :approved

    model.sequel_to_jsonmodel(ds.all)
  end
end
