require 'spec_helper'

describe 'Runcorn Representations' do

  let! (:top_container) { create(:json_top_container) }

  it "won't allow delete of an archival object with representations" do
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

    expect { ao.delete }.to raise_error(ConflictException)
  end

  it "won't allow delete of an archival object with child with representations" do
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

    expect { series.delete }.to raise_error(ConflictException)
    expect { parent.delete }.to raise_error(ConflictException)
  end

end