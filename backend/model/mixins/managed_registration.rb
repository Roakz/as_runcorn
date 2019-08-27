module ManagedRegistration
  def self.prepended(base)
    class << base
      prepend(ClassMethods)
    end
  end

  def update_from_json(json, opts = {}, apply_nested_records = true)
    # no updating submissions
    if self.registration_state == 'submitted'
      raise ReadOnlyException.new("Can't update an object that has been submitted for registration." +
                                  " Withdraw submission to edit the draft.")
    end

    if AppConfig[:plugins].include?('qsa_migration_adapter')
      # You're the boss.  Monkey away!
    else
      # no monkeying with registration state!
      json['registration_state'] = self.registration_state
    end

    super(json, opts, apply_nested_records)
  end

  module ClassMethods
    def create_from_json(json, opts = {})
      # these are the defaults, but just in case someone is trying to break the rules!
      json['registration_state'] = 'draft'
      json['publish'] = false

      super(json, opts)
    end

    def populate_display_name(json)
      super

      unless json['registration_state'] == 'approved'
        ['sort_name', 'primary_name'].each do |field|
          if json.display_name.has_key?(field)
            json.display_name[field] = "[#{json['registration_state'].upcase}] #{json.display_name[field]}"
          end
        end
      end
    end
  end
end
