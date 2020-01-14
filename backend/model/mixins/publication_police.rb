module PublicationPolice

  def self.included(base)
    base.extend(ClassMethods)
  end

  def update_from_json(json, opts = {}, apply_nested_records = true)
    current_user = User[:username => RequestContext.get(:current_username)]
    unless current_user.can?('update_publish_flag')
      json['publish'] = self.publish == 1
    end
    super
  end

  module ClassMethods
    def create_from_json(json, extra_values = {})
      # only police top level records coz nested ones get created on every update
      # and they don't get published independently anyway
      if self.top_level?
        current_user = User[:username => RequestContext.get(:current_username)]
        unless !current_user.can?('update_publish_flag')
          json['publish'] = false
        end
      end
      super
    end
  end
end
