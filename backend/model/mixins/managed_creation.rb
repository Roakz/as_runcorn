module ManagedCreation

  def self.prepended(base)
    class << base
      prepend(ClassMethods)
    end
  end

  def update_from_json(json, opts = {}, apply_nested_records = true)
    # no monkeying with draft status!
    json['draft'] = self.draft == 1

    # no publishing drafts!
    json['publish'] = false if json['draft']

    super(json, opts, apply_nested_records)
  end

  module ClassMethods
    def create_from_json(json, opts = {})
      # these are the defaults, but just in case someone is trying to break the rules!
      json['draft'] = true
      json['publish'] = false

      super(json, opts)
    end

    def populate_display_name(json)
      super

      if json['draft']
        ['sort_name', 'primary_name'].each do |field|
          if json.display_name.has_key?(field) && json.display_name[field] !~ /^\[DRAFT\] /
            json.display_name[field] = '[DRAFT] ' + json.display_name[field]
          end
        end
      end
    end
  end
end
