require 'spec_helper'

describe 'Runcorn Conservation Requests' do

  it "lets you link representations to it directly" do
    conservation_request = ConservationRequest.get_or_die(create(:json_conservation_request).id)

    top_container = create(:json_top_container)

    ao_obj = create(:json_archival_object,
                    :physical_representations => [
                      {
                        "title" => "bad song",
                        "description" => "Let us get physical!",
                        "current_location" => "N/A",
                        "normal_location" => "N/A",
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
                        "normal_location" => "N/A",
                      }
                    ])
    ao = ArchivalObject.to_jsonmodel(ao_obj.id)

    physical_representation = ao.physical_representations.fetch(0)
    digital_representation = ao.digital_representations.fetch(0)

    conservation_request.add_representations(PhysicalRepresentation, JSONModel.parse_reference(physical_representation.fetch('uri')).fetch(:id))
    conservation_request.add_representations(DigitalRepresentation, JSONModel.parse_reference(digital_representation.fetch('uri')).fetch(:id))

    # And now I can see the conservation request on the representations in question
    ao = ArchivalObject.to_jsonmodel(ao_obj.id)

    # ao
    require 'pp';$stderr.puts("\n*** DEBUG #{(Time.now.to_f * 1000).to_i} [model_conservation_request_spec.rb:43 e9daf]: " + {%Q^ao^ => ao}.pretty_inspect + "\n")

    ao.physical_representations.dig(0, 'conservation_requests', 0, 'ref').should eq(conservation_request.uri)
    ao.digital_representations.dig(0, 'conservation_requests', 0, 'ref').should eq(conservation_request.uri)

  end

end
