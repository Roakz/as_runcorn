require 'spec_helper'

describe 'Physical representations' do

  it "applies to archival objects and resources" do
    [[:json_archival_object, ArchivalObject], [:json_resource, Resource]].each do |factory, model|
      json = build(factory)

      json.physical_representations = [
        {
          "description" => "Let us get physical!",
          "current_location" => "N/A",
          "normal_location" => "N/A",
          "format" => "OTH",
          "preservation_restriction_status" => "FIXME",
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

  it "removes representations that are no longer referenced" do
    json = build(:json_archival_object)

    json.physical_representations = [
      {
        "description" => "Let us get physical!",
        "current_location" => "N/A",
        "normal_location" => "N/A",
        "format" => "OTH",
        "preservation_restriction_status" => "FIXME",
      }
    ]

    obj = ArchivalObject.create_from_json(json)

    json = ArchivalObject.to_jsonmodel(obj.id)

    dead_uri = json.physical_representations[0]['existing_ref']

    json.physical_representations = []
    obj.update_from_json(json)

    json = ArchivalObject.to_jsonmodel(obj.id)
    expect(json.physical_representations.length).to eq(0)
    expect(Tombstone[:uri => dead_uri]).to be_truthy
  end

end
