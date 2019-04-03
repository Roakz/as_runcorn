require 'spec_helper'

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
end
