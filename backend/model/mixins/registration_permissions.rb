module RegistrationPermissions
  def self.prepended(base)
    class << base
      prepend(ClassMethods)
    end
  end

  def after_create
    super

    # add "manage_agency_registration" to "repository-managers" on repo create
    RequestContext.open(:repo_id => self.id) do
      group = Group.filter(:group_code => 'repository-managers', :repo_id => self.id).first
      group.grant('manage_agency_registration') unless group.nil?
    end

    Notifications.notify("REPOSITORY_CHANGED")
  end

  module ClassMethods
  end
end
