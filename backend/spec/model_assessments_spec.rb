require 'spec_helper'

describe 'Runcorn Assessments' do

  let(:surveyor) { create(:json_agent_person) }

  let!(:physical_representation_uri) {
    ao = create(:json_archival_object, {
                  "physical_representations" => [
                                                 {
                                                   "title" => "Great song",
                                                   "description" => "Let us get physical!",
                                                   "current_location" => "N/A",
                                                   "normal_location" => "N/A",
                                                   "format" => "Drafting Cloth (Linen)",
                                                   "contained_within" => "OTH",
                                                   "container" => {"ref" => create(:json_top_container).uri},
                                                 }
                                                ]
                })
    ao['physical_representations'].first['uri']
  }


  it "can link physical representations" do
    assessment = Assessment.create_from_json(build(:json_assessment, {
                                                     'records' => [{'ref' => physical_representation_uri}],
                                                     'surveyed_by' => [{'ref' => surveyor.uri}],
                                                   }))
  end


end
