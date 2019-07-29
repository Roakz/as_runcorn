require 'spec_helper'

describe 'Runcorn Conservation Treatments' do

  let(:conservator) {
    JSONModel(:user).find(make_test_user("conservator").id)[:agent_record]['ref']
  }

  let!(:top_container) { create(:json_top_container) }

  let!(:series) { create(:json_resource) }

  let!(:top_level_ao) {
    create(:json_archival_object, :resource => {'ref' => series.uri})
  }

  let!(:unsaved_child_ao) {
    build(:json_archival_object,
           :resource => {'ref' => series.uri},
           :parent => {'ref' => top_level_ao.uri})
  }

  it "can be attached to a physical representation" do
    treatment = build(:json_conservation_treatment)
    rep_json = build(:json_physical_representation, {
      'conservation_treatments' => [treatment]
    })

    ao_json = unsaved_child_ao
    ao_json['physical_representations'] = [rep_json]
    ao = ArchivalObject.create_from_json(ao_json)

    ao_json = ArchivalObject.to_jsonmodel(ao.id)
    expect(ao_json.physical_representations.dig(0, 'conservation_treatments').length).to eq(1)
    expect(ao_json.physical_representations.dig(0, 'conservation_treatments', 0, 'status')).to eq(ConservationTreatment::STATUS_COMPLETED)
    expect(ao_json.physical_representations.dig(0, 'conservation_treatments', 0, 'start_date')).to eq(treatment['start_date'])
    expect(ao_json.physical_representations.dig(0, 'conservation_treatments', 0, 'end_date')).to eq(treatment['end_date'])
    expect(ao_json.physical_representations.dig(0, 'conservation_treatments', 0, 'treatment_process')).to eq(treatment['treatment_process'])
    expect(ao_json.physical_representations.dig(0, 'conservation_treatments', 0, 'materials_used_consumables')).to eq(treatment['materials_used_consumables'])
    expect(ao_json.physical_representations.dig(0, 'conservation_treatments', 0, 'materials_used_staff_time')).to eq(treatment['materials_used_staff_time'])
    expect(ao_json.physical_representations.dig(0, 'conservation_treatments', 0, 'external_reference')).to eq(treatment['external_reference'])
  end

  it "has a status of awaiting treatment when not started" do
    treatment = {}

    rep_json = build(:json_physical_representation, {
      'conservation_treatments' => [treatment]
    })

    ao_json = unsaved_child_ao
    ao_json['physical_representations'] = [rep_json]
    ao = ArchivalObject.create_from_json(ao_json)

    ao_json = ArchivalObject.to_jsonmodel(ao.id)
    expect(ao_json.physical_representations.dig(0, 'conservation_treatments', 0, 'status')).to eq(ConservationTreatment::STATUS_AWAITING_TREATMENT)
  end

  it "has a status of in progress when started" do
    treatment = build(:json_conservation_treatment, {:end_date => nil})

    rep_json = build(:json_physical_representation, {
      'conservation_treatments' => [treatment]
    })

    ao_json = unsaved_child_ao
    ao_json['physical_representations'] = [rep_json]
    ao = ArchivalObject.create_from_json(ao_json)

    ao_json = ArchivalObject.to_jsonmodel(ao.id)
    expect(ao_json.physical_representations.dig(0, 'conservation_treatments', 0, 'status')).to eq(ConservationTreatment::STATUS_IN_PROGRESS)
  end

  it "can be linked to a user" do
    treatment = build(:json_conservation_treatment, {
      :user => {
        :ref => conservator
      }
    })

    rep_json = build(:json_physical_representation, {
      'conservation_treatments' => [treatment]
    })

    ao_json = unsaved_child_ao
    ao_json['physical_representations'] = [rep_json]
    ao = ArchivalObject.create_from_json(ao_json)

    ao_json = ArchivalObject.to_jsonmodel(ao.id)
    expect(ao_json.physical_representations.dig(0, 'conservation_treatments', 0, 'user', 'ref')).to eq(conservator)
  end

end