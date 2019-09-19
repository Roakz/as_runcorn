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


  it "lets you add an action" do
    batch = Batch.create_from_json(build(:json_batch))

    2.times do
      tcon = create(:json_top_container)
      batch.add_objects(:top_container, JSONModel.parse_reference(tcon['uri'])[:id])
    end

    batch.add_action(:functional_move, 'location' => 'PER')

    json = URIResolver.resolve_references(Batch.to_jsonmodel(batch[:id]), ['actions']) 

    expect(json['actions'].first['_resolved']['action_type']).to eq('functional_move')
  end


  it 'does not let you add an action if it already has a current action' do
    batch = Batch.create_from_json(build(:json_batch))
    batch.add_action(:functional_move, 'location' => 'PER')
    expect{batch.add_action(:functional_move, 'location' => 'HOME')}.to raise_error(Batch::InvalidAction)
  end


  it "lets you perform an action" do
    batch = Batch.create_from_json(build(:json_batch))

    2.times do
      tcon = create(:json_top_container)
      batch.add_objects(:top_container, JSONModel.parse_reference(tcon['uri'])[:id])
    end

    batch.add_action(:functional_move, 'location' => 'PER')
    batch.perform_action

    batch.object_refs.each do |uri|
      expect(TopContainer.to_jsonmodel(JSONModel.parse_reference(uri)[:id])['current_location']).to eq('PER')
    end

    batch.add_action(:functional_move, 'location' => 'HOME')

    json = URIResolver.resolve_references(Batch.to_jsonmodel(batch[:id]), ['actions']) 
    expect(json['actions'][0]['_resolved']['action_status']).to eq('executed')
    expect(json['actions'][1]['_resolved']['action_status']).to eq('draft')

    batch.perform_action

    batch.object_refs.each do |uri|
      expect(TopContainer.to_jsonmodel(JSONModel.parse_reference(uri)[:id])['current_location']).to eq('HOME')
    end

    json = URIResolver.resolve_references(Batch.to_jsonmodel(batch[:id]), ['actions']) 

    pp json
  end


  it "complains if you try to add an action with an unknown type" do
    batch = Batch.create_from_json(build(:json_batch))
    expect{batch.add_action(:unknown_action_type)}.to raise_error(BatchActionHandler::UnknownActionType)
  end


  it "complains if you try to add an action with bad params" do
    batch = Batch.create_from_json(build(:json_batch))
    expect{batch.add_action(:functional_move)}.to raise_error(BatchActionHandler::InvalidParams)
    expect{batch.add_action(:functional_move, 'moocation' => 'HOME')}.to raise_error(BatchActionHandler::InvalidParams)
    expect{batch.add_action(:functional_move, 'location' => 'moooooo')}.to raise_error(BatchActionHandler::InvalidParams)
  end
end
