class RapProvisioner

  def self.doit!
    Repository.dataset.select(:id).each do |row|
      RequestContext.open(:repo_id => row[:id]) do
        Resource.filter(:repo_id => row[:id]).each do |resource|
          p "Provisioning RAPs for resource: #{resource.id}"
          Resource.rap_needs_propagate(resource.id)
        end
      end
    end
  end

end
