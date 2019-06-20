require 'spec_helper'

describe 'Runcorn Movements Mixin' do

  it "gives you a list of models using the mixin" do
    expect(Movements.models.empty?).to eq(false)
    Movements.models.map do |m|
      expect(m.ancestors.include?(ASModel)).to eq(true)
    end
  end


  it "keeps track of physical representation movements" do
    tcon = create(:json_top_container)

    json = build(:json_archival_object)

    json.physical_representations =
      [
       {
         "title" => "bad song",
         "description" => "Let us get physical!",
         "current_location" => "CONS",
         "normal_location" => "HOME",
         "format" => "Drafting Cloth (Linen)",
         "contained_within" => "OTH",
         "container" => {"ref" => tcon.uri},
         "movements" =>
         [
          {
            "functional_location" => "CONS",
            "user" => "admin",
            "move_context" => { "ref" => "/file_issues/1"},
            "move_date" => "2019-06-06"
          }
         ]
       }
      ]

    obj = ArchivalObject.create_from_json(json)
    json = ArchivalObject.to_jsonmodel(obj.id)

    prep = json.physical_representations[0]

    expect(prep['movements'].length).to eq(1)
    expect(prep['movements'][0]['functional_location']).to eq('CONS')
  end


  it "keeps track of top container movements" do
    json = build(:json_top_container)

    json.movements = 
      [
       {
         "functional_location" => "CONS",
         "user" => "admin",
         "move_date" => "2019-06-06"
       }
      ]

    obj = TopContainer.create_from_json(json)
    json = TopContainer.to_jsonmodel(obj.id)

    expect(json['movements'].length).to eq(1)
    expect(json['movements'][0]['functional_location']).to eq('CONS')
  end

  it "supports moves to storage locations" do
    location = create(:json_location)

    json = build(:json_top_container)

    json.movements = 
      [
       {
         "storage_location" => {"ref" => location.uri},
         "user" => "admin",
         "move_date" => "2019-06-06"
       }
      ]

    obj = TopContainer.create_from_json(json)
    json = TopContainer.to_jsonmodel(obj.id)

    expect(json['movements'].length).to eq(1)
    expect(json['movements'][0]['storage_location']["ref"]).to eq(location.uri)
  end

  it "insists exactly one of function or storage location is specified" do
    location = create(:json_location)

    json = build(:json_top_container)

    json.movements = 
      [
       {
         "storage_location" => {"ref" => location.uri},
         "functional_location" => "CONS",
         "user" => "admin",
         "move_date" => "2019-06-06"
       }
      ]

    expect {TopContainer.create_from_json(json)}.to raise_error(JSONModel::ValidationException)

    json.movements = 
      [
       {
         "user" => "admin",
         "move_date" => "2019-06-06"
       }
      ]

    expect {TopContainer.create_from_json(json)}.to raise_error(JSONModel::ValidationException)
  end

  it "sets current location to the value of the latest movement and sorts movements by move date" do
    tcon = create(:json_top_container)

    json = build(:json_archival_object)

    json.physical_representations =
      [
       {
         "title" => "bad song",
         "description" => "Let us get physical!",
         "current_location" => "PER", # wrong - should be fixed on update
         "normal_location" => "HOME",
         "format" => "Drafting Cloth (Linen)",
         "contained_within" => "OTH",
         "container" => {"ref" => tcon.uri},
         "movements" =>
         [ # deliberately out of order - should be fixed on update
          {
            "functional_location" => "HOME",
            "user" => "admin",
            "move_context" => { "ref" => "/file_issues/1"},
            "move_date" => "2019-05-05" # here and next have same date
          },
          {
            "functional_location" => "CONS",
            "user" => "admin",
            "move_date" => "2019-05-05" # original order should break the tie
          },
          {
            "functional_location" => "PER", # with agency
            "user" => "admin",
            "move_context" => { "ref" => "/file_issues/1"},
            "move_date" => "2019-04-04"
          },
          {
            "functional_location" => "HOME",
            "user" => "admin",
            "move_date" => "2019-03-03"
          },
          {
            "functional_location" => "HOME",
            "user" => "admin",
            "move_date" => "2019-01-01"
          },
         ]
       }
      ]

    obj = ArchivalObject.create_from_json(json)
    json = ArchivalObject.to_jsonmodel(obj.id)

    prep = json.physical_representations[0]

    expect(prep['current_location']).to eq('CONS')

    expect(prep['movements'].last['functional_location']).to eq('CONS')

  end

  it "does not allow moves to storage for non-storable models" do
    location = create(:json_location)

    json = build(:json_archival_object)

    json.physical_representations =
      [
       {
         "title" => "bad song",
         "description" => "Let us get physical!",
         "current_location" => "CONS",
         "normal_location" => "HOME",
         "format" => "Drafting Cloth (Linen)",
         "contained_within" => "OTH",
         "movements" =>
         [
          {
            "storage_location" => {"ref" => location.uri},
            "user" => "admin",
            "move_date" => "2019-06-06"
          }
         ]
       }
      ]

    expect {ArchivalObject.create_from_json(json)}.to raise_error(JSONModel::ValidationException)
  end

  it 'provides a handy move method' do
    location = create(:json_location)

    json = build(:json_top_container)

    tc = TopContainer.create_from_json(json)

    mvmt = {
      :user => 'test_monkey'
    }

    tc.move(mvmt)

    json = TopContainer.to_jsonmodel(tc.id)

    # defaults to home
    expect(json['movements'][0]['functional_location']).to eq('HOME')
  end
end
