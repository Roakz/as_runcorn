require 'spec_helper'

describe 'Runcorn Deaccessions' do
  let! (:top_container) { create(:json_top_container) }

  describe 'on Series' do
    it "can be not deaccessioned" do
      series = create(:json_resource)

      json = Resource.to_jsonmodel(series.id)
      json.deaccessions.length.should eq(0)
      json.deaccessioned.should be_falsey
    end

    it "can be deaccessioned" do
      series = create(:json_resource, {
        "deaccessions" => [
          build(:json_deaccession, {'scope' => 'whole'})
        ],
      })

      json = Resource.to_jsonmodel(series.id)
      json.deaccessions.length.should eq(1)
      json.deaccessioned.should be_truthy
    end

    it "representation counts take into account deaccessions via inheritance" do
      series = create(:json_resource)

      parent = create(:json_archival_object, {
        "resource" => {"ref" => series.uri}
      })

      deaccessioned_child = create(:json_archival_object, {
        "parent" => {"ref" => parent.uri},
        "resource" => {"ref" => series.uri},
        "deaccessions" => [
          build(:json_deaccession, {'scope' => 'whole'})
        ],
        "physical_representations" => [
          {
            "title" => "Great song",
            "description" => "Let us get physical!",
            "current_location" => "N/A",
            "format" => "Drafting Cloth (Linen)",
            "contained_within" => "OTH",
            "container" => {"ref" => top_container.uri},
          }
        ],
        "digital_representations" => [
          {
            "title" => "bad song",
            "description" => "Let us get digital!",
            "file_type" => "JPEG",
            "contained_within" => "Floppy Disk",
          }
        ],
      })

      child = create(:json_archival_object, {
        "parent" => {"ref" => parent.uri},
        "resource" => {"ref" => series.uri},
        "physical_representations" => [
          {
            "title" => "Another great song",
            "description" => "Let us get physical!",
            "current_location" => "N/A",
            "format" => "Drafting Cloth (Linen)",
            "contained_within" => "OTH",
            "container" => {"ref" => top_container.uri},
          }
        ],
        "digital_representations" => [
          {
            "title" => "bad song",
            "description" => "Let us get digital!",
            "file_type" => "JPEG",
            "contained_within" => "Floppy Disk",
          }
        ],
      })

      json = Resource.to_jsonmodel(series.id)
      json['physical_representations_count'].should eq(1)
      json['digital_representations_count'].should eq(1)
    end

    it "representation counts take into account deaccessioned representations" do
      series = create(:json_resource)

      parent = create(:json_archival_object, {
        "resource" => {"ref" => series.uri}
      })

      deaccessioned_child = create(:json_archival_object, {
        "parent" => {"ref" => parent.uri},
        "resource" => {"ref" => series.uri},
        "physical_representations" => [
          {
            "title" => "Great song",
            "description" => "Let us get physical!",
            "current_location" => "N/A",
            "format" => "Drafting Cloth (Linen)",
            "contained_within" => "OTH",
            "container" => {"ref" => top_container.uri},
          }
        ],
        "digital_representations" => [
          {
            "title" => "bad song",
            "description" => "Let us get digital!",
            "file_type" => "JPEG",
            "contained_within" => "Floppy Disk",
            "deaccessions" => [
              build(:json_deaccession, {'scope' => 'whole'})
            ],
          }
        ],
      })

      child = create(:json_archival_object, {
        "parent" => {"ref" => parent.uri},
        "resource" => {"ref" => series.uri},
        "deaccessions" => [
          build(:json_deaccession, {'scope' => 'whole'})
        ],
        "physical_representations" => [
          {
            "title" => "Another great song",
            "description" => "Let us get physical!",
            "current_location" => "N/A",
            "format" => "Drafting Cloth (Linen)",
            "contained_within" => "OTH",
            "container" => {"ref" => top_container.uri},
            "deaccessions" => [
              build(:json_deaccession, {'scope' => 'whole'})
            ],
          }
        ],
        "digital_representations" => [
          {
            "title" => "bad song",
            "description" => "Let us get digital!",
            "file_type" => "JPEG",
            "contained_within" => "Floppy Disk",
          }
        ],
      })

      json = Resource.to_jsonmodel(series.id)
      json['physical_representations_count'].should eq(1)
      json['digital_representations_count'].should eq(0)
    end
  end

  describe 'on Archival Objects' do
    it "can be not deaccessioned" do
      ao = create(:json_archival_object)

      json = ArchivalObject.to_jsonmodel(ao.id)
      json.deaccessions.length.should eq(0)
      json.deaccessioned.should be_falsey
    end

    it "can be deaccessioned" do
      ao = create(:json_archival_object, {
        "deaccessions" => [
          build(:json_deaccession, {'scope' => 'whole'})
        ],
      })

      json = ArchivalObject.to_jsonmodel(ao.id)
      json.deaccessions.length.should eq(1)
      json.deaccessioned.should be_truthy
    end

    it "inherits deaccession status from parent record" do
      series = create(:json_resource)

      parent = create(:json_archival_object, {
        "resource" => {"ref" => series.uri},
        "deaccessions" => [
          build(:json_deaccession, {'scope' => 'whole'})
        ],
      })

      ao = create(:json_archival_object, {
        "resource" => {"ref" => series.uri},
        "parent" => {"ref" => parent.uri}
      })

      json = ArchivalObject.to_jsonmodel(ao.id)
      json.deaccessions.length.should eq(0)
      json.deaccessioned.should be_truthy
    end

    it "inherits deaccession status from series" do
      series = create(:json_resource, {
        "deaccessions" => [
          build(:json_deaccession, {'scope' => 'whole'})
        ],
      })

      parent = create(:json_archival_object, {
        "resource" => {"ref" => series.uri}
      })

      child = create(:json_archival_object, {
        "parent" => {"ref" => parent.uri},
        "resource" => {"ref" => series.uri},
      })

      parent_json = ArchivalObject.to_jsonmodel(parent.id)
      parent_json.deaccessions.length.should eq(0)
      parent_json.deaccessioned.should be_truthy

      child_json = ArchivalObject.to_jsonmodel(child.id)
      child_json.deaccessions.length.should eq(0)
      child_json.deaccessioned.should be_truthy
    end
  end

  describe 'on Physical Representations' do

    it "can be deaccessioned on its own" do
      ao = create(:json_archival_object, {
        "physical_representations" => [
          {
            "title" => "Great song",
            "description" => "Let us get physical!",
            "current_location" => "N/A",
            "format" => "Drafting Cloth (Linen)",
            "contained_within" => "OTH",
            "container" => {"ref" => top_container.uri},
            "deaccessions" => [
              build(:json_deaccession, {'scope' => 'whole'})
            ],
          }
        ]
      })

      ao_json = ArchivalObject.to_jsonmodel(ao.id)
      ao_json.deaccessions.length.should eq(0)
      ao_json.deaccessioned.should be_falsey

      rep_json = PhysicalRepresentation.to_jsonmodel(ao.physical_representations.first['id'])
      rep_json.deaccessions.length.should eq(1)
      rep_json.deaccessioned.should be_truthy
    end

    it "can inherit deaccession status from controlling record" do
      ao = create(:json_archival_object, {
        "deaccessions" => [
          build(:json_deaccession, {'scope' => 'whole'})
        ],
        "physical_representations" => [
          {
            "title" => "Great song",
            "description" => "Let us get physical!",
            "current_location" => "N/A",
            "format" => "Drafting Cloth (Linen)",
            "contained_within" => "OTH",
            "container" => {"ref" => top_container.uri},
          }
        ]
      })

      ao_json = ArchivalObject.to_jsonmodel(ao.id)
      ao_json.deaccessions.length.should eq(1)
      ao_json.deaccessioned.should be_truthy

      rep_json = PhysicalRepresentation.to_jsonmodel(ao.physical_representations.first['id'])
      rep_json.deaccessions.length.should eq(0)
      rep_json.deaccessioned.should be_truthy
    end

    it "can inherit deaccession status from series" do
      series = create(:json_resource, {
        "deaccessions" => [
          build(:json_deaccession, {'scope' => 'whole'})
        ],
      })

      parent = create(:json_archival_object, {
        "resource" => {"ref" => series.uri}
      })

      child = create(:json_archival_object, {
        "parent" => {"ref" => parent.uri},
        "resource" => {"ref" => series.uri},
        "physical_representations" => [
          {
            "title" => "Great song",
            "description" => "Let us get physical!",
            "current_location" => "N/A",
            "format" => "Drafting Cloth (Linen)",
            "contained_within" => "OTH",
            "container" => {"ref" => top_container.uri},
          }
        ]
      })

      rep_json = PhysicalRepresentation.to_jsonmodel(child.physical_representations.first['id'])
      rep_json.deaccessions.length.should eq(0)
      rep_json.deaccessioned.should be_truthy
    end

    it 'has container removed upon deaccession' do
      ao = create(:json_archival_object, {
        "physical_representations" => [
          {
            "title" => "Great song",
            "description" => "Let us get physical!",
            "current_location" => "N/A",
            "format" => "Drafting Cloth (Linen)",
            "contained_within" => "OTH",
            "container" => {"ref" => top_container.uri},
          }
        ]
      })

      rep_id = ao.physical_representations.first['id']

      rep_json = PhysicalRepresentation.to_jsonmodel(rep_id)
      rep_json.deaccessioned.should be_falsy
      rep_json['deaccessions'] = [build(:json_deaccession, {'scope' => 'whole'})]

      PhysicalRepresentation[rep_id].update_from_json(rep_json)

      rep_json = PhysicalRepresentation.to_jsonmodel(rep_id)
      rep_json.deaccessioned.should be_truthy
      rep_json.container.should be_nil
    end

    it 'has container removed upon deaccession of parent record' do
      series = create(:json_resource)

      parent = create(:json_archival_object, {
        "resource" => {"ref" => series.uri}
      })

      child = create(:json_archival_object, {
        "parent" => {"ref" => parent.uri},
        "resource" => {"ref" => series.uri},
        "physical_representations" => [
          {
            "title" => "Great song",
            "description" => "Let us get physical!",
            "current_location" => "N/A",
            "format" => "Drafting Cloth (Linen)",
            "contained_within" => "OTH",
            "container" => {"ref" => top_container.uri},
          }
        ]
      })

      rep_id = child.physical_representations.first['id']

      ao_json = ArchivalObject.to_jsonmodel(parent.id)
      ao_json.deaccessioned.should be_falsy
      ao_json['deaccessions'] = [build(:json_deaccession, {'scope' => 'whole'})]

      ArchivalObject[parent.id].update_from_json(ao_json)

      rep_json = PhysicalRepresentation.to_jsonmodel(rep_id)
      rep_json.deaccessioned.should be_truthy
      rep_json.container.should be_nil
    end

    it 'has container removed upon deaccession of the resource' do
      series = create(:json_resource)

      parent = create(:json_archival_object, {
        "resource" => {"ref" => series.uri}
      })

      child = create(:json_archival_object, {
        "parent" => {"ref" => parent.uri},
        "resource" => {"ref" => series.uri},
        "physical_representations" => [
          {
            "title" => "Great song",
            "description" => "Let us get physical!",
            "current_location" => "N/A",
            "format" => "Drafting Cloth (Linen)",
            "contained_within" => "OTH",
            "container" => {"ref" => top_container.uri},
          }
        ]
      })

      rep_id = child.physical_representations.first['id']

      series_json = Resource.to_jsonmodel(series.id)
      series_json.deaccessioned.should be_falsy
      series_json['deaccessions'] = [build(:json_deaccession, {'scope' => 'whole'})]

      Resource[series.id].update_from_json(series_json)

      rep_json = PhysicalRepresentation.to_jsonmodel(rep_id)
      rep_json.deaccessioned.should be_truthy
      rep_json.container.should be_nil
    end
  end

  describe 'on Digital Representations' do

    it "can be deaccessioned on its own" do
      ao = create(:json_archival_object, {
        "digital_representations" => [
          {
            "title" => "bad song",
            "description" => "Let us get digital!",
            "file_type" => "JPEG",
            "contained_within" => "Floppy Disk",
            "deaccessions" => [
              build(:json_deaccession, {'scope' => 'whole'})
            ],
          }
        ]
      })

      ao_json = ArchivalObject.to_jsonmodel(ao.id)
      ao_json.deaccessions.length.should eq(0)
      ao_json.deaccessioned.should be_falsey

      rep_json = DigitalRepresentation.to_jsonmodel(ao.digital_representations.first['id'])
      rep_json.deaccessions.length.should eq(1)
      rep_json.deaccessioned.should be_truthy
    end

    it "can inherit deaccession status from controlling record" do
      ao = create(:json_archival_object, {
        "deaccessions" => [
          build(:json_deaccession, {'scope' => 'whole'})
        ],
        "digital_representations" => [
          {
            "title" => "bad song",
            "description" => "Let us get digital!",
            "file_type" => "JPEG",
            "contained_within" => "Floppy Disk",
            "container" => {"ref" => top_container.uri},
          }
        ]
      })

      ao_json = ArchivalObject.to_jsonmodel(ao.id)
      ao_json.deaccessions.length.should eq(1)
      ao_json.deaccessioned.should be_truthy

      rep_json = DigitalRepresentation.to_jsonmodel(ao.digital_representations.first['id'])
      rep_json.deaccessions.length.should eq(0)
      rep_json.deaccessioned.should be_truthy
    end

    it "can inherit deaccession status from series" do
      series = create(:json_resource, {
        "deaccessions" => [
          build(:json_deaccession, {'scope' => 'whole'})
        ],
      })

      parent = create(:json_archival_object, {
        "resource" => {"ref" => series.uri}
      })

      child = create(:json_archival_object, {
        "parent" => {"ref" => parent.uri},
        "resource" => {"ref" => series.uri},
        "digital_representations" => [
          {
            "title" => "bad song",
            "description" => "Let us get digital!",
            "file_type" => "JPEG",
            "contained_within" => "Floppy Disk",
            "container" => {"ref" => top_container.uri},
          }
        ]
      })

      rep_json = DigitalRepresentation.to_jsonmodel(child.digital_representations.first['id'])
      rep_json.deaccessions.length.should eq(0)
      rep_json.deaccessioned.should be_truthy
    end
  end
end