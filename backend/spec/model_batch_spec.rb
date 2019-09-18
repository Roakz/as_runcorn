require 'spec_helper'

describe 'Runcorn Batch' do

  it "knows which models it supports" do
    models = Batch.models
    expect(models.empty?).to eq(false)
    expect{Batch.models.map{|m| JSONModel(m)}}.to_not raise_error
  end


  it "lets you add objects to it" do
    agency = create(:json_agent_corporate_entity)
    batch = Batch.create_from_json(build(:json_batch))
    batch.add_objects(:agent_corporate_entity, JSONModel.parse_reference(agency['uri'])[:id])

    expect(batch.object_refs).to eq([agency['uri']])
  end


  it "lets you remove objects from it" do
    agency = create(:json_agent_corporate_entity)
    batch = Batch.create_from_json(build(:json_batch))
    batch.add_objects(:agent_corporate_entity, JSONModel.parse_reference(agency['uri'])[:id])
    batch.remove_objects(:agent_corporate_entity, JSONModel.parse_reference(agency['uri'])[:id])

    expect(batch.object_refs).to eq([])
  end


  it "does not let you add objects of unsupported models" do
    batch = Batch.create_from_json(build(:json_batch))

    expect{batch.add_objects(:agent_software, 1)}.to raise_error(Batch::UnsupportedModel)
  end

  it "gives a count of objects by model" do
    batch = Batch.create_from_json(build(:json_batch))
    expect(batch.object_counts).to eq({})

    4.times do
      agency = create(:json_agent_corporate_entity)
      batch.add_objects(:agent_corporate_entity, JSONModel.parse_reference(agency['uri'])[:id])
    end

    3.times do
      tcon = create(:json_top_container)
      batch.add_objects(:top_container, JSONModel.parse_reference(tcon['uri'])[:id])
    end

    counts = batch.object_counts
    expect(counts[:agent_corporate_entity]).to eq(4)
    expect(counts[:top_container]).to eq(3)
  end


  it "gives a list of the currently included models" do
    agency = create(:json_agent_corporate_entity)
    batch = Batch.create_from_json(build(:json_batch))
    expect(batch.included_models).to eq([])

    batch.add_objects(:agent_corporate_entity, JSONModel.parse_reference(agency['uri'])[:id])

    expect(batch.included_models).to eq([:agent_corporate_entity])
  end


  it "ignores duplicates" do
    agency = create(:json_agent_corporate_entity)
    batch = Batch.create_from_json(build(:json_batch))
    batch.add_objects(:agent_corporate_entity, JSONModel.parse_reference(agency['uri'])[:id])
    batch.add_objects(:agent_corporate_entity, JSONModel.parse_reference(agency['uri'])[:id])

    expect(batch.object_refs).to eq([agency['uri']])
  end


  it "has a handy display string" do
    agency = create(:json_agent_corporate_entity)
    batch = Batch.create_from_json(build(:json_batch))
    batch.add_objects(:agent_corporate_entity, JSONModel.parse_reference(agency['uri'])[:id])

    json = Batch.to_jsonmodel(batch[:id]).to_hash

    expect(json['display_string'].empty?).to_not be_truthy
  end
end
