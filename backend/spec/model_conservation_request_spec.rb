require 'spec_helper'

describe 'Runcorn Conservation Requests' do

  let!(:conservation_request) { ConservationRequest.get_or_die(create(:json_conservation_request).id) }
  let!(:top_container) { create(:json_top_container) }

  let!(:series) { create(:json_resource) }

  let!(:top_level_ao) {
    create(:json_archival_object, :resource => {'ref' => series.uri})
  }

  let!(:ao_with_representations) {
    create(:json_archival_object,
           :resource => {'ref' => series.uri},
           :parent => {'ref' => top_level_ao.uri},
           :physical_representations => [
             {
               "title" => "bad song",
               "description" => "Let us get physical!",
               "current_location" => "N/A",
               "format" => "Drafting Cloth (Linen)",
               "contained_within" => "OTH",
               "container" => {"ref" => top_container.uri},
             }
           ],
           :digital_representations => [
             {
               "title" => "bad song",
               "description" => "Let us get digital!",
               "file_type" => "JPEG",
               "contained_within" => "Floppy Disk",
             }
           ])
  }

  let!(:top_level_ao_with_representation) {
    create(:json_archival_object,
           :resource => {'ref' => series.uri},
           :physical_representations => [
             {
               "title" => "wax lips",
               "description" => "wax lips",
               "current_location" => "N/A",
               "format" => "Drafting Cloth (Linen)",
               "contained_within" => "OTH",
               "container" => {"ref" => top_container.uri},
             }
           ])
  }

  it "lets you link representations to it directly" do
    ao = ArchivalObject.to_jsonmodel(ao_with_representations.id)

    physical_representation = ao.physical_representations.fetch(0)

    conservation_request.add_physical_representations(JSONModel.parse_reference(physical_representation.fetch('uri')).fetch(:id))

    # And now I can see the conservation request on the representations in question
    ao = ArchivalObject.to_jsonmodel(ao_with_representations.id)

    expect(ao.physical_representations.dig(0, 'conservation_requests', 0, 'ref')).to eq(conservation_request.uri)
  end

  it "accepts all representations under an AO" do
    conservation_request.add_archival_objects(top_level_ao.id)

    # Same deal as above: the representations have been linked to our
    # conservation request.
    ao = ArchivalObject.to_jsonmodel(ao_with_representations.id)

    expect(ao.physical_representations.dig(0, 'conservation_requests', 0, 'ref')).to eq(conservation_request.uri)
  end

  it "accepts all representations under a series" do
    conservation_request.add_resources(series.id)

    # Same deal as above: the representations have been linked to our
    # conservation request.
    ArchivalObject.to_jsonmodel(ao_with_representations.id).tap do |ao|
      expect(ao.physical_representations.dig(0, 'conservation_requests', 0, 'ref')).to eq(conservation_request.uri)
    end

    # And the other top-level AO's representations got them too
    ArchivalObject.to_jsonmodel(top_level_ao_with_representation.id).tap do |ao|
      expect(ao.physical_representations.dig(0, 'conservation_requests', 0, 'ref')).to eq(conservation_request.uri)
    end
  end

  it "accepts all representations in a top container" do
    conservation_request.add_top_containers(top_container.id)

    ao = ArchivalObject.to_jsonmodel(ao_with_representations.id)

    expect(ao.physical_representations.dig(0, 'conservation_requests', 0, 'ref')).to eq(conservation_request.uri)
  end

  it "lets you remove a series from a conservation request" do
    conservation_request.add_resources(series.id)
    conservation_request.remove_resources(series.id)

    ao = ArchivalObject.to_jsonmodel(ao_with_representations.id)
    expect(ao.physical_representations.dig(0, 'conservation_requests')).to eq([])
  end

  it "lets you remove an AO from a conservation request" do
    conservation_request.add_resources(series.id)
    conservation_request.remove_archival_objects(ao_with_representations.id)

    # The representations under the removed AO are no longer linked
    ArchivalObject.to_jsonmodel(ao_with_representations.id).tap do |ao|
      expect(ao.physical_representations.dig(0, 'conservation_requests')).to eq([])
    end

    # But the top-level AO's representations are right as rain
    ArchivalObject.to_jsonmodel(top_level_ao_with_representation.id).tap do |ao|
      expect(ao.physical_representations.dig(0, 'conservation_requests', 0, 'ref')).to eq(conservation_request.uri)
    end
  end

  it "lets you remove specific representations from a conservation request" do
    conservation_request.add_resources(series.id)

    ao = ArchivalObject.to_jsonmodel(ao_with_representations.id)
    physical_representation = ao.physical_representations.fetch(0)
    conservation_request.remove_physical_representations(JSONModel.parse_reference(physical_representation.fetch('uri')).fetch(:id))

    ArchivalObject.to_jsonmodel(ao_with_representations.id).tap do |ao|
      # Physical representation gone
      expect(ao.physical_representations.dig(0, 'conservation_requests')).to eq([])
    end
  end

  it "lets you remove entire top containers from a conservation request" do
    conservation_request.add_resources(series.id)
    conservation_request.remove_top_containers(top_container.id)

    ao = ArchivalObject.to_jsonmodel(ao_with_representations.id)

    # The physical representation is gone because it was in the removed top
    # container
    expect(ao.physical_representations.dig(0, 'conservation_requests')).to eq([])
  end
end
