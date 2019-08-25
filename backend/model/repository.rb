Repository.prepend(RegistrationPermissions)

class Repository
  # Make sure the default RAP exists from the outset
  def after_create
    if self.repo_code == Repository.GLOBAL
      # No need for a RAP on this one.
      return
    end

    RequestContext.open(:repo_id => self.id) do
      DB.attempt {
        RAP.get_default_id
      }.and_if_constraint_fails do |e|
        Log.warn("Constraint failure while creating default RAP: #{e}")
      end
    end
  end
end
