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
    json = Assessment.to_jsonmodel(assessment.id)

    expect(JSONModel.parse_reference(json.records.first['ref'])[:type]).to eq('physical_representation')
  end

  it 'permits setting a value for a proposed_treatment attribute' do
    # actually reusing the 'format' type

    definitions = AssessmentAttributeDefinitions.get($repo_id)
    format_id = definitions.definitions.select{|df| df[:type] == 'format'}.first[:id]

    assessment = Assessment.create_from_json(build(:json_assessment, {
                                                     'records' => [{'ref' => physical_representation_uri}],
                                                     'surveyed_by' => [{'ref' => surveyor.uri}],
                                                     'formats' => [
                                                                   {
                                                                     "definition_id" => format_id,
                                                                     "value" => "5",
                                                                   }
                                                                  ],
                                                   }))
    json = Assessment.to_jsonmodel(assessment.id)

    expect(json.formats.first['value']).to eq("5")
  end

  it 'can have external_ids' do
    assessment = Assessment.create_from_json(build(:json_assessment, {
                                                     'records' => [{'ref' => physical_representation_uri}],
                                                     'surveyed_by' => [{'ref' => surveyor.uri}],
                                                     'external_ids' => [
                                                                        {
                                                                          'source' => 'ARK',
                                                                          'external_id' => '999-999-9999'

                                                                        }
                                                                       ]
                                                   }))
    json = Assessment.to_jsonmodel(assessment.id)

    expect(json.external_ids.first['source']).to eq('ARK')
  end

  it 'can have a treatment_priority' do
    assessment = Assessment.create_from_json(build(:json_assessment, {
                                                     'records' => [{'ref' => physical_representation_uri}],
                                                     'surveyed_by' => [{'ref' => surveyor.uri}],
                                                     'treatment_priority' => 'HIGH',
                                                   }))
    json = Assessment.to_jsonmodel(assessment.id)

    expect(json.treatment_priority).to eq('HIGH')
  end

end
