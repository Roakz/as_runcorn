# Back in 028 we got rid of the idea of having representations link to sub
# containers.  Remove any rows that were created during that process.

require 'db/migrations/utils'

Sequel.migration do

  up do
    self.transaction do
      self[:top_container_link_rlshp].delete
    end
  end

end
