require 'spec_helper'
require_relative 'spec_helper_ext'

describe 'Runcorn Agencies' do

  describe 'Agency Categories' do

    it 'allows an agent corporate to be created with a category' do
      agent = create(:json_agent_corporate_entity,
                     :agency_category => 'LOC')

      expect JSONModel(:agent_corporate_entity).find(agent.id).agency_category.should eq('LOC')
    end

  end

  describe 'Agency External Ids' do

    it 'lets agents have external ids' do
      the_source = 'ARK'
      the_id = 'ABCDE-12345-67890-12345-67890'

      agent = create(:json_agent_corporate_entity,
                     'external_ids' => [{
                                          'source' => the_source,
                                          'external_id' => the_id,
                                        }])

      expect JSONModel(:agent_corporate_entity).find(agent.id).external_ids.first['source'].should eq(the_source)
      expect JSONModel(:agent_corporate_entity).find(agent.id).external_ids.first['external_id'].should eq(the_id)
    end
  end

  describe 'No Delete For You' do

    it "allows delete of an agency created in error without any links" do
      agent = create(:json_agent_corporate_entity)
      agent.delete
      AgentCorporateEntity[agent.id].should be_nil
    end

    it "allows delete of an agency linked via a standard ASpace relationship" do
      associated_agent = create(:json_agent_corporate_entity)

      relationship = JSONModel(:agent_relationship_associative).new
      relationship.relator = "is_associative_with"
      relationship.ref = associated_agent.uri

      agent = create(:json_agent_corporate_entity,
                     'related_agents' => [relationship.to_hash])

      agent.delete

      AgentCorporateEntity[agent.id].should be_nil
    end

    it "disallow delete of an agency linked via a series system relationship" do
      associated_agent = create(:json_agent_corporate_entity)

      relationship = JSONModel(:series_system_agent_agent_association_relationship).new
      relationship.ref = associated_agent.uri
      relationship.relator = 'is_associated_with'
      relationship.start_date = '1999-01-01'

      agent = create(:json_agent_corporate_entity,
                     'series_system_agent_relationships' => [relationship.to_hash])

      expect {
        agent.delete
      }.to raise_error(ConflictException)

      AgentCorporateEntity[agent.id].should_not be_nil
    end
  end

end
