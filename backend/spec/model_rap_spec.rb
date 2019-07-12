require 'spec_helper'

describe 'Runcorn RAPs' do

  it "supports attaching RAPs to archival objects" do
    series = create(:json_resource)

    parent = create(:json_archival_object,
                    :resource => {'ref' => series.uri},
                    :rap_attached => {
                      'open_access_metadata' => true,
                      'access_status' => 'Open Access',
                      'access_category' => 'N/A',

                      'years' => 10,
                      'change_description' => 'test',
                      'authorised_by' => 'me',
                      'change_date' => '2019-01-01',
                      'approved_by' => 'you',
                      'internal_reference' => '4a2b6588-11bb-4b98-a575-8109da2f44ea',
                    })

    ao = ArchivalObject.to_jsonmodel(parent.id)

    expect(ao['rap_attached']['internal_reference']).to eq('4a2b6588-11bb-4b98-a575-8109da2f44ea')
  end

  it "inherits RAPs attached to archival objects down to representations" do
    series = create(:json_resource)

    parent = create(:json_archival_object,
                    :resource => {'ref' => series.uri},
                    :rap_attached => {
                      'open_access_metadata' => true,
                      'access_status' => 'Open Access',
                      'access_category' => 'N/A',

                      'years' => 10,
                      'change_description' => 'test',
                      'authorised_by' => 'me',
                      'change_date' => '2019-01-01',
                      'approved_by' => 'you',
                      'internal_reference' => '4a2b6588-11bb-4b98-a575-8109da2f44ea',
                    })

    child = create(:json_archival_object,
                   :resource => {'ref' => series.uri},
                   :parent => {'ref' => parent.uri},
                   :physical_representations => [
                     build(:json_physical_representation)
                   ])

    ao = ArchivalObject.to_jsonmodel(child.id)

    expect(ao.physical_representations[0].fetch('rap_applied').fetch('internal_reference')).to eq('4a2b6588-11bb-4b98-a575-8109da2f44ea')
    expect(ao.physical_representations[0].fetch('rap_history', []).length).to eq(1)
    expect(ao.physical_representations[0].fetch('rap_history')[0]['is_active']).to be_truthy
    expect(ao.physical_representations[0].fetch('rap_history')[0]['version']).to eq(0)
    expect(ao.physical_representations[0].fetch('rap_history')[0]['ref']).to be_truthy
  end

  it "updates RAP history as overrides are added" do
    series = create(:json_resource)

    parent = create(:json_archival_object,
                    :resource => {'ref' => series.uri},
                    :rap_attached => {
                      'open_access_metadata' => true,
                      'access_status' => 'Open Access',
                      'access_category' => 'N/A',

                      'years' => 10,
                      'change_description' => 'test',
                      'authorised_by' => 'me',
                      'change_date' => '2019-01-01',
                      'approved_by' => 'you',
                      'internal_reference' => '4a2b6588-11bb-4b98-a575-8109da2f44ea',
                    })

    child = create(:json_archival_object,
                   :resource => {'ref' => series.uri},
                   :parent => {'ref' => parent.uri},
                   :physical_representations => [
                     build(:json_physical_representation)
                   ])

    ao = ArchivalObject.to_jsonmodel(child.id)

    ao['rap_attached'] = {
      'open_access_metadata' => true,
      'access_status' => 'Open Access',
      'access_category' => 'N/A',

      'years' => 100,
      'change_description' => 'override',
      'authorised_by' => 'me',
      'change_date' => '2019-01-01',
      'approved_by' => 'you',
      'internal_reference' => 'd4e4edda-c57b-44b5-a76d-b35c811fb15f',
    }

    ArchivalObject[ao.id].update_from_json(ao)

    updated = ArchivalObject.to_jsonmodel(ao.id)

    expect(updated.physical_representations[0].fetch('rap_applied').fetch('internal_reference')).to eq('d4e4edda-c57b-44b5-a76d-b35c811fb15f')
    expect(updated.physical_representations[0].fetch('rap_history', []).length).to eq(2)
  end

end
