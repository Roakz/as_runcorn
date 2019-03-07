require 'spec_helper'

describe 'Physical representations' do

  it "applies to archival objects and resources" do
    [[:json_archival_object, ArchivalObject], [:json_resource, Resource]].each do |factory, model|
      json = build(factory)

      json.physical_representations = [
        {
          "description" => "Let us get physical!",
        }
      ]

      obj = model.create_from_json(json)

      json = model.to_jsonmodel(obj.id)

      expect(json.physical_representations.length).to eq(1)
      expect(json.physical_representations[0]['existing_ref']).to be_truthy
      expect(json.physical_representations[0]['description']).to eq("Let us get physical!")

      # And we can update it...
      json.physical_representations[0]['description'] = "I hated that song..."

      obj.update_from_json(json)

      json = model.to_jsonmodel(obj.id)
      expect(json.physical_representations.length).to eq(1)
      expect(json.physical_representations[0]['existing_ref']).to be_truthy
      expect(json.physical_representations[0]['description']).to eq("I hated that song...")
    end
  end

end
