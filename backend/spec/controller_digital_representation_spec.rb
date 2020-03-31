require 'spec_helper'

describe 'Runcorn Digital representations' do

  it "applies to archival objects" do
    json = build(:json_archival_object)

    json.digital_representations = [
      {
        "title" => "bad song",
        "description" => "Let us get digital!",
        "file_type" => "JPEG",
        "contained_within" => "Floppy Disk",
      }
    ]

    obj = ArchivalObject.create_from_json(json)

    json = ArchivalObject.to_jsonmodel(obj.id)

    expect(json.digital_representations.length).to eq(1)
    expect(json.digital_representations[0]['existing_ref']).to be_truthy
    expect(json.digital_representations[0]['description']).to eq("Let us get digital!")

    # And we can update it...
    json.digital_representations[0]['description'] = "I hated that song..."

    obj.update_from_json(json)

    json = ArchivalObject.to_jsonmodel(obj.id)
    expect(json.digital_representations.length).to eq(1)
    expect(json.digital_representations[0]['existing_ref']).to be_truthy
    expect(json.digital_representations[0]['description']).to eq("I hated that song...")
  end

  it "removes representations that are no longer referenced" do
    json = build(:json_archival_object)

    json.digital_representations = [
      {
        "title" => "bad song",
        "description" => "Let us get digital!",
        "file_type" => "JPEG",
        "contained_within" => "Floppy Disk",
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

  it "provides representation counts on the archival object" do
    obj = create(:json_archival_object, {
      "digital_representations" => [
        {
          "title" => "bad song",
          "description" => "Let us get digital!",
          "file_type" => "JPEG",
          "contained_within" => "Floppy Disk",
        },
        {
          "title" => "also a bad song",
          "description" => "Let us also not get too digital",
          "file_type" => "JPEG",
          "contained_within" => "Floppy Disk",
        },
      ]
    })

    json = ArchivalObject.to_jsonmodel(obj.id)
    json['digital_representations_count'].should eq(2)
  end


  it "provides representation counts on the resource" do
    resource = create(:json_resource)
    ao_1 = create(:json_archival_object, {
      "resource" => {"ref" => resource.uri},
      "digital_representations" => [
        {
          "title" => "bad song",
          "description" => "Let us get digital!",
          "file_type" => "JPEG",
          "contained_within" => "Floppy Disk",
        },
        {
          "title" => "also a bad song",
          "description" => "Let us also not get too digital",
          "file_type" => "JPEG",
          "contained_within" => "Floppy Disk",
        },
      ]
    })
    ao_2 = create(:json_archival_object, {
      "resource" => {"ref" => resource.uri},
      "digital_representations" => [
        {
          "title" => "bad tv",
          "description" => "Let us watch TV",
          "file_type" => "JPEG",
          "contained_within" => "Floppy Disk",
        },
      ]
    })

    json = Resource.to_jsonmodel(resource.id)
    json['digital_representations_count'].should eq(3)
  end

end
