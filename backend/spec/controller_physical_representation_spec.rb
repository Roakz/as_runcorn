require 'spec_helper'

describe 'Runcorn Physical representations' do

  let! (:top_container) { create(:json_top_container) }

  it "applies to archival objects" do
    json = build(:json_archival_object)

    json.physical_representations = [
      {
        "title" => "bad song",
        "description" => "Let us get physical!",
        "current_location" => "N/A",
        "normal_location" => "N/A",
        "format" => "Drafting Cloth (Linen)",
        "contained_within" => "OTH",
        "container" => {"ref" => top_container.uri},
      }
    ]

    obj = ArchivalObject.create_from_json(json)

    json = ArchivalObject.to_jsonmodel(obj.id)

    expect(json.physical_representations.length).to eq(1)
    expect(json.physical_representations[0]['existing_ref']).to be_truthy
    expect(json.physical_representations[0]['description']).to eq("Let us get physical!")

    # And we can update it...
    json.physical_representations[0]['description'] = "I hated that song..."

    obj.update_from_json(json)

    json = ArchivalObject.to_jsonmodel(obj.id)
    expect(json.physical_representations.length).to eq(1)
    expect(json.physical_representations[0]['existing_ref']).to be_truthy
    expect(json.physical_representations[0]['description']).to eq("I hated that song...")
  end

  it "removes representations that are no longer referenced" do
    json = build(:json_archival_object)

    json.physical_representations = [
      {
        "title" => "bad song",
        "description" => "Let us get physical!",
        "current_location" => "N/A",
        "normal_location" => "N/A",
        "format" => "Drafting Cloth (Linen)",
        "contained_within" => "OTH",
        "container" => {"ref" => top_container.uri},
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

  it "provides representation counts on the archival object" do
    obj = create(:json_archival_object, {
      "physical_representations" => [
        {
          "title" => "bad song",
          "description" => "Let us get physical!",
          "current_location" => "N/A",
          "normal_location" => "N/A",
          "format" => "Drafting Cloth (Linen)",
          "contained_within" => "OTH",
          "container" => {"ref" => top_container.uri},
        },
        {
          "title" => "also a bad song",
          "description" => "Let us also not get too physical",
          "current_location" => "N/A",
          "normal_location" => "N/A",
          "format" => "Drafting Cloth (Linen)",
          "contained_within" => "OTH",
          "container" => {"ref" => top_container.uri},
        },
      ]
    })

    json = ArchivalObject.to_jsonmodel(obj.id)
    json['physical_representations_count'].should eq(2)
  end


  it "provides representation counts on the resource" do
    resource = create(:json_resource)
    ao_1 = create(:json_archival_object, {
      "resource" => {"ref" => resource.uri},
      "physical_representations" => [
        {
          "title" => "bad song",
          "description" => "Let us get physical!",
          "current_location" => "N/A",
          "normal_location" => "N/A",
          "format" => "Drafting Cloth (Linen)",
          "contained_within" => "OTH",
          "container" => {"ref" => top_container.uri},
        },
        {
          "title" => "also a bad song",
          "description" => "Let us also not get too physical",
          "current_location" => "N/A",
          "normal_location" => "N/A",
          "format" => "Drafting Cloth (Linen)",
          "contained_within" => "OTH",
          "container" => {"ref" => top_container.uri},
        },
      ]
    })
    ao_2 = create(:json_archival_object, {
      "resource" => {"ref" => resource.uri},
      "physical_representations" => [
        {
          "title" => "bad tv",
          "description" => "Let us watch TV",
          "current_location" => "N/A",
          "normal_location" => "N/A",
          "format" => "Drafting Cloth (Linen)",
          "contained_within" => "OTH",
          "container" => {"ref" => top_container.uri},
        },
      ]
    })

    json = Resource.to_jsonmodel(resource.id)
    json['physical_representations_count'].should eq(3)
  end

end
