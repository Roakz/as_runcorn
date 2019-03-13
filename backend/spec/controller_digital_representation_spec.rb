require 'spec_helper'

describe 'Digital representations' do

  it "applies to archival objects and resources" do
    [[:json_archival_object, ArchivalObject], [:json_resource, Resource]].each do |factory, model|
      json = build(factory)

      json.digital_representations = [
        {
          "description" => "Let us get digital!",
          "current_location" => "N/A",
          "normal_location" => "N/A",
          "format" => "OTH",
        }
      ]

      obj = model.create_from_json(json)

      json = model.to_jsonmodel(obj.id)

      expect(json.digital_representations.length).to eq(1)
      expect(json.digital_representations[0]['existing_ref']).to be_truthy
      expect(json.digital_representations[0]['description']).to eq("Let us get digital!")

      # And we can update it...
      json.digital_representations[0]['description'] = "I hated that song..."

      obj.update_from_json(json)

      json = model.to_jsonmodel(obj.id)
      expect(json.digital_representations.length).to eq(1)
      expect(json.digital_representations[0]['existing_ref']).to be_truthy
      expect(json.digital_representations[0]['description']).to eq("I hated that song...")
    end
  end

  it "removes representations that are no longer referenced" do
    json = build(:json_archival_object)

    json.digital_representations = [
      {
        "description" => "Let us get digital!",
        "current_location" => "N/A",
        "normal_location" => "N/A",
        "format" => "OTH",
      }
    ]

    obj = ArchivalObject.create_from_json(json)

    json = ArchivalObject.to_jsonmodel(obj.id)

    dead_uri = json.digital_representations[0]['existing_ref']

    json.digital_representations = []
    obj.update_from_json(json)

    json = ArchivalObject.to_jsonmodel(obj.id)
    expect(json.digital_representations.length).to eq(0)
    expect(Tombstone[:uri => dead_uri]).to be_truthy
  end

end
