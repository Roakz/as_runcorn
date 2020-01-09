class RuncornReport

  def build_aspace_agency_map(aspacedb, aspace_agency_ids)
    aspacedb[:name_corporate_entity]
      .join(:agent_corporate_entity, Sequel.qualify(:agent_corporate_entity, :id) => Sequel.qualify(:name_corporate_entity, :agent_corporate_entity_id))
      .filter(:agent_corporate_entity_id => aspace_agency_ids)
      .filter(:is_display_name => 1)
      .select(Sequel.qualify(:agent_corporate_entity, :id),
              Sequel.qualify(:agent_corporate_entity, :qsa_id),
              Sequel.qualify(:name_corporate_entity, :sort_name))
      .map {|row|
        [row[:id], row]
      }.to_h
  end

end