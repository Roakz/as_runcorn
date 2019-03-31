require 'spec_helper'

describe 'Runcorn Managed Registration Controller' do

  before(:each) do
    submitter = make_test_user("submitter")
    Group[:group_code => 'repository-archivists', :repo_id => $repo_id].add_user(submitter)

    approver = make_test_user("approver")
    Group[:group_code => 'repository-managers', :repo_id => $repo_id].add_user(approver)

    nobody = make_test_user("nobody")
  end

  describe "Agency" do
    let!(:agency) do
      AgentCorporateEntity.create_from_json(build(:json_agent_corporate_entity))
    end

    it 'can be submitted' do
      as_test_user('submitter') do
        url = URI("#{JSONModel::HTTP.backend_url}/agents/corporate_entities/#{agency.id}/submit")
        response = JSONModel::HTTP.post_json(url, {})
        response.code.should eq("200")
      end
    end


    it 'can be withdrawn' do
      as_test_user('submitter') do
        url = URI("#{JSONModel::HTTP.backend_url}/agents/corporate_entities/#{agency.id}/submit")
        response = JSONModel::HTTP.post_json(url, {})

        url = URI("#{JSONModel::HTTP.backend_url}/agents/corporate_entities/#{agency.id}/withdraw")
        response = JSONModel::HTTP.post_json(url, {})
        response.code.should eq("200")
      end
    end


    it 'can be approved' do
      as_test_user('submitter') do
        url = URI("#{JSONModel::HTTP.backend_url}/agents/corporate_entities/#{agency.id}/submit")
        response = JSONModel::HTTP.post_json(url, {})
      end

      as_test_user('approver') do
        url = URI("#{JSONModel::HTTP.backend_url}/agents/corporate_entities/#{agency.id}/approve")
        response = JSONModel::HTTP.post_json(url, {})
        response.code.should eq("200")
      end
    end


    it 'can only be submitted by a submitter' do
      as_test_user('nobody') do
        url = URI("#{JSONModel::HTTP.backend_url}/agents/corporate_entities/#{agency.id}/submit")
        response = JSONModel::HTTP.post_json(url, {})
        response.code.should eq("403")
      end
    end


    it 'can only be approved by an approver' do
      as_test_user('submitter') do
        url = URI("#{JSONModel::HTTP.backend_url}/agents/corporate_entities/#{agency.id}/submit")
        response = JSONModel::HTTP.post_json(url, {})

        url = URI("#{JSONModel::HTTP.backend_url}/agents/corporate_entities/#{agency.id}/approve")
        response = JSONModel::HTTP.post_json(url, {})
        response.code.should eq("403")
      end
    end


    it 'will give a list of agencies at each stage of registration' do
      list_url = URI("#{JSONModel::HTTP.backend_url}/agents/corporate_entities/registrations/all")
      response = JSONModel::HTTP.get_json(list_url)
      response['draft'].select{|a| a['uri'] == agency.uri}.length.should eq(1)

      as_test_user('submitter') do
        url = URI("#{JSONModel::HTTP.backend_url}/agents/corporate_entities/#{agency.id}/submit")
        response = JSONModel::HTTP.post_json(url, {})
      end

      response = JSONModel::HTTP.get_json(list_url)
      response['submitted'].select{|a| a['uri'] == agency.uri}.length.should eq(1)

      as_test_user('submitter') do
        url = URI("#{JSONModel::HTTP.backend_url}/agents/corporate_entities/#{agency.id}/withdraw")
        response = JSONModel::HTTP.post_json(url, {})
      end

      response = JSONModel::HTTP.get_json(list_url)
      response['withdrawn'].select{|a| a['uri'] == agency.uri}.length.should eq(1)

      as_test_user('approver') do
        url = URI("#{JSONModel::HTTP.backend_url}/agents/corporate_entities/#{agency.id}/submit")
        response = JSONModel::HTTP.post_json(url, {})
        url = URI("#{JSONModel::HTTP.backend_url}/agents/corporate_entities/#{agency.id}/approve")
        response = JSONModel::HTTP.post_json(url, {})
      end

      response = JSONModel::HTTP.get_json(list_url)
      response['approved'].select{|a| a['uri'] == agency.uri}.length.should eq(1)
    end
  end
end
