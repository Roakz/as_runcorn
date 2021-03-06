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
      'internal_reference' => 'd4e4edda-c57b-44b5-a76d-b35c811fb15f',
    }

    ArchivalObject[ao.id].update_from_json(ao)

    updated = ArchivalObject.to_jsonmodel(ao.id)

    expect(updated.physical_representations[0].fetch('rap_applied').fetch('internal_reference')).to eq('d4e4edda-c57b-44b5-a76d-b35c811fb15f')
    expect(updated.physical_representations[0].fetch('rap_history', []).length).to eq(2)
  end

  it "clears the link of an existing RAP when it is replaced" do
    series = create(:json_resource)

    created_ao = create(:json_archival_object,
                        :resource => {'ref' => series.uri},
                        :rap_attached => {
                          'open_access_metadata' => true,
                          'access_status' => 'Open Access',
                          'access_category' => 'N/A',

                          'years' => 10,
                          'internal_reference' => '4a2b6588-11bb-4b98-a575-8109da2f44ea',
                        })


    json = ArchivalObject.to_jsonmodel(created_ao.id)

    json['rap_attached'] = {
      'open_access_metadata' => true,
      'access_status' => 'Open Access',
      'access_category' => 'N/A',

      'years' => 100,
      'internal_reference' => '4a2b6588-11bb-4b98-a575-8109da2f44ea',
    }

    ArchivalObject[created_ao.id].update_from_json(json)

    expect(RAP.filter(:archival_object_id => created_ao.id).count).to eq(1)
  end

  it "allows a RAP to be attached to a series" do
    series = create(:json_resource,
                    :rap_attached => {
                      'open_access_metadata' => true,
                      'access_status' => 'Open Access',
                      'access_category' => 'N/A',

                      'years' => 11,
                      'internal_reference' => 'cc8f30cc-9534-4bbb-92e6-fb3a7732b480',
                    })

    child = create(:json_archival_object,
                   :resource => {'ref' => series.uri},
                   :physical_representations => [
                     build(:json_physical_representation)
                   ])

    ao = ArchivalObject.to_jsonmodel(child.id)

    expect(ao.physical_representations[0].fetch('rap_applied').fetch('internal_reference')).to eq('cc8f30cc-9534-4bbb-92e6-fb3a7732b480')
  end

  it "allows a RAP to be edited and bumps lock versions appropriately" do
    series = create(:json_resource,
                    :rap_attached => {
                      'open_access_metadata' => true,
                      'access_status' => 'Open Access',
                      'access_category' => 'N/A',

                      'years' => 11,
                      'internal_reference' => 'cc8f30cc-9534-4bbb-92e6-fb3a7732b480',
                    })

    child = create(:json_archival_object,
                   :resource => {'ref' => series.uri},
                   :physical_representations => [
                     build(:json_physical_representation)
                   ])

    original_series_lock_version = Resource.get_or_die(series.id).lock_version
    original_series_system_mtime = Resource.get_or_die(series.id).system_mtime

    original_ao_lock_version = ArchivalObject.get_or_die(child.id).lock_version
    original_ao_system_mtime = ArchivalObject.get_or_die(child.id).system_mtime

    # Edit the RAP on the series
    rap_uri = Resource.to_jsonmodel(series.id).rap_attached['uri']
    rap = RAP.to_jsonmodel(JSONModel.parse_reference(rap_uri).fetch(:id))
    rap.years = 100
    RAP.get_or_die(rap.id).update_from_json(rap)

    # The series should have updated, as should have the AO with the representation
    expect(Resource.get_or_die(series.id).lock_version).to eq(original_series_lock_version + 1)
    expect(Resource.get_or_die(series.id).system_mtime).to be > original_series_system_mtime

    expect(ArchivalObject.get_or_die(child.id).lock_version).to eq(original_ao_lock_version + 1)
    expect(ArchivalObject.get_or_die(child.id).system_mtime).to be > original_ao_system_mtime
  end

  describe "expiry calculation" do

    it "nothing lasts forever" do
      series = create(:json_resource,
                      :rap_attached => {
                        'open_access_metadata' => true,
                        'access_status' => 'Restricted Access',
                        'access_category' => 'N/A',
                        'internal_reference' => 'cc8f30cc-9534-4bbb-92e6-fb3a7732b480',
                      })

      ao = create(:json_archival_object,
                  :resource => {'ref' => series.uri},
                  :physical_representations => [
                    build(:json_physical_representation)
                  ])

      ao_json = ArchivalObject.to_jsonmodel(ao.id)

      expect(ao_json.physical_representations[0].fetch('rap_expiration')['expiry_date']).to be_nil
      expect(ao_json.physical_representations[0].fetch('rap_expiration')['expired']).to be_falsey
      expect(ao_json.physical_representations[0].fetch('rap_expiration')['expires']).to be_falsey
    end

    it "something never lasts" do
      series = create(:json_resource,
                      :rap_attached => {
                        'open_access_metadata' => true,
                        'years' => 10,
                        'access_status' => 'Restricted Access',
                        'access_category' => 'N/A',
                        'internal_reference' => 'cc8f30cc-9534-4bbb-92e6-fb3a7732b480',
                      })

      ao = create(:json_archival_object,
                  :resource => {'ref' => series.uri},
                  :dates => [
                    build(:json_date, {
                      'begin' => '2000-01-01',
                      'end' => '2001-01-01',
                      'label' => 'existence',
                    })
                  ],
                  :physical_representations => [
                    build(:json_physical_representation)
                  ])

      ao_json = ArchivalObject.to_jsonmodel(ao.id)

      expect(ao_json.physical_representations[0].fetch('rap_expiration')['expiry_date']).to_not be_nil
      expect(ao_json.physical_representations[0].fetch('rap_expiration')['expired']).to be_truthy
      expect(ao_json.physical_representations[0].fetch('rap_expiration')['expires']).to be_truthy
    end
  end
end
