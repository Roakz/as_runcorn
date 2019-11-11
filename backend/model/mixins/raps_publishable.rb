module RAPsPublishable

  def self.included(base)
    base.extend(ClassMethods)
  end

  def reset_publish_based_on_rap_applied!
    if AppConfig[:plugins].include?('qsa_migration_adapter')
      # Nothing to do if we're in migration land
      return
    end

    # If RAP propagation is deferred, we're in an import and don't want to
    # monkey with the publish flag anyway.
    return if RAP.deferred_propagations_active?

    self.refresh

    return if self.publish != 1 # do nothing if unpublished

    rap_data = RAPsApplied::RAPApplications.new([self])

    rap = rap_data.rap_json_for_rap_applied(self.id)

    return if rap.open_access_metadata

    rap_expiry = rap_data.rap_expiration_for_rap_applied(self.id)

    return if rap_expiry.fetch('expired')

    # Ok, the RAP implies that the record cannot be published
    self.publish = 0
    self.save
  end

  def update_from_json(json, opts = {}, apply_nested_records = true)
    obj = super
    obj.reset_publish_based_on_rap_applied!
    obj
  end

  module ClassMethods
    def create_from_json(json, opts = {})
      obj = super
      obj.reset_publish_based_on_rap_applied!
      obj
    end
  end
end
