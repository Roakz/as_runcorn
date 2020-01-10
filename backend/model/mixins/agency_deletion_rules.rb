module AgencyDeletionRules
  def delete
    # There is a speical permission required for deleting agencies.
    # Checking here as a last resort
    current_user = User[:username => RequestContext.get(:current_username)]
    unless current_user.can?('delete_agency')
      raise AccessDeniedException.new('Insufficient privileges to delete agency')
    end

    # check for series system relationships
    if self.trace_all.any? { |_, relationships| !relationships.empty? }
      raise ConflictException.new("This agent has series system relationships and cannot be removed")
    end

    # check for MAP reference
    MAPDB.open do |map_db|
      if map_db[:agency][:aspace_agency_id => self.id]
        raise ConflictException.new("This agent has been referenced in the MAP and cannot be removed")
      end
    end

    super
  end
end
