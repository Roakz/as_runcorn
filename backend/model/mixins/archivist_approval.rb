module ArchivistApproval

  def self.included(base)
    base.extend(ClassMethods)
  end

  def update_from_json(json, opts = {}, apply_nested_records = true)
    unless User[:username => RequestContext.get(:current_username)].can?('approve_records')
      original = self.class.to_jsonmodel(self)

      self.class.reset_approval_fields(json, original)
    end

    super
  end

  module ClassMethods
    def create_from_json(json, extra_values = {})
      unless User[:username => RequestContext.get(:current_username)].can?('approve_records')
        reset_approval_fields(json)
      end

      super
    end

    def reset_approval_fields(json, defaults = {})
      json['archivist_approved'] = defaults['archivist_approved']
      json['approval_date'] = defaults['approval_date']
      json['approved_by'] = defaults['approved_by']
    end
  end

end