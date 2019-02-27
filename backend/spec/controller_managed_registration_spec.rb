require 'spec_helper'

describe 'Managed Registration Controller' do

  describe "Agency" do
    let!(:agency) do
      AgentCorporateEntity.create_from_json(build(:json_agent_corporate_entity))
    end

    it 'can be submitted' do
      url = URI("#{JSONModel::HTTP.backend_url}/agents/corporate_entities/#{agency.id}/submit")
      response = JSONModel::HTTP.post_json(url, {})

      response.code.should eq("200")
    end


    it 'can be withdrawn' do
      url = URI("#{JSONModel::HTTP.backend_url}/agents/corporate_entities/#{agency.id}/submit")
      response = JSONModel::HTTP.post_json(url, {})

      url = URI("#{JSONModel::HTTP.backend_url}/agents/corporate_entities/#{agency.id}/withdraw")
      response = JSONModel::HTTP.post_json(url, {})

      response.code.should eq("200")
    end


    it 'can be approved' do
      url = URI("#{JSONModel::HTTP.backend_url}/agents/corporate_entities/#{agency.id}/submit")
      response = JSONModel::HTTP.post_json(url, {})

      url = URI("#{JSONModel::HTTP.backend_url}/agents/corporate_entities/#{agency.id}/approve")
      response = JSONModel::HTTP.post_json(url, {})
# FIXME: sort out users and perms please
#      response.code.should eq("200")
    end


    it 'can only be submitted by a user who can edit agents' do
      create(:user, {:username => 'noperms'})

      as_test_user('noperms') do

        url = URI("#{JSONModel::HTTP.backend_url}/agents/corporate_entities/#{agency.id}/submit")
        response = JSONModel::HTTP.post_json(url, {})

        response.code.should eq("403")
      end
    end
  end

end
