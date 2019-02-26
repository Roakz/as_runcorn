require 'spec_helper'

describe 'Managed Registration' do

  describe "Agency" do
    let!(:agency) do
      AgentCorporateEntity.create_from_json(build(:json_agent_corporate_entity))
    end


    it 'comes into life as a draft' do
      expect(agency.registration_state).to eq('draft')
    end


    it 'can be submitted for approval' do
      Registration.submit(agency)

      expect(agency.registration_state).to eq('submitted')
    end


    it 'can be withdrawn from consideration' do
      Registration.submit(agency)
      Registration.withdraw(agency)

      expect(agency.registration_state).to eq('draft')
    end


    it 'can be approved' do
      Registration.submit(agency)
      Registration.approve(agency)

      expect(agency.registration_state).to eq('approved')
    end


    it 'cannot be approved until it has been submitted' do
      Registration.approve(agency)

      expect(agency.registration_state).to eq('draft')
    end


    it 'cannot be edited while submitted' do
      Registration.submit(agency)

      expect{ agency.update_from_json(JSONModel(:agent_corporate_entity).find(agency.id)) }.to raise_error(ReadOnlyException)
    end
  end

end
