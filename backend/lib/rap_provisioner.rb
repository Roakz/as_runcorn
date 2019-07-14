class RapProvisioner

  def self.doit!
    Repository.dataset.select(:id).each do |row|
      RequestContext.open(:repo_id => row[:id]) do
        Resource.filter(:repo_id => row[:id]).each do |resource|
          p "Provisioning RAPs for resource: #{resource.id}"
          resource.propagate_raps!
        end
      end
    end
  end

end