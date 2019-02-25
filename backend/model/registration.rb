class Registration

  ACTION_STATES = {
    :submit => :submitted,
    :withdraw => :draft,
    :approve => :approved
  }

  def self.handle_action(obj, action)
    if obj.registration_state.intern == ACTION_STATES[action]
      return {
        :message => "Already #{ACTION_STATES[action]}. No change.",
        :state => obj.registration_state,
        :user => obj.registration_last_user,
        :time => obj.registration_last_time.getlocal
      }
    end

    if obj.registration_state.intern == :draft && action == :approve
      return {
        :message => "Can't approve a draft. Please submit first. No change.",
        :state => obj.registration_state,
        :user => obj.registration_last_user,
        :time => obj.registration_last_time.getlocal
      }
    end

    user = RequestContext.get(:current_username)
    time = Time.now

    obj.update(:registration_state => ACTION_STATES[action],
               :registration_last_user => user,
               :registration_last_time => time,
               :publish => 0,
               :user_mtime => time,
               :last_modified_by => user)

    {
      :message => 'Success',
      :state => ACTION_STATES[action],
      :user => user,
      :time => time
    }
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
end
