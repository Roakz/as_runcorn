require 'spec_helper'

describe 'Runcorn QSA Id model' do

  QSAId.models.each do |model|
    it "generates a qsa id from a sequence on #{model} create" do
      obj1 = model.create_from_json(build("json_#{model.my_jsonmodel.record_type}".intern))
      obj2 = model.create_from_json(build("json_#{model.my_jsonmodel.record_type}".intern))
      expect(obj2.qsa_id).to eq(obj1.qsa_id + 1)
    end
  end

  QSAId.models.each do |model|
    if existing_id = QSAId.existing_id_for(model)
      it "copies the generated qsa id into an #{model} existing id (#{existing_id}) field if asked to" do
        obj = model.create_from_json(build("json_#{model.my_jsonmodel.record_type}".intern))

        # need the jsonmodel because of four part id shenanigans
        json_id = model.my_jsonmodel.find(obj.id)[existing_id].to_s
        expect(json_id).to eq(obj.qsa_id.to_s)
      end
    end
  end


  it 'uses a different sequence for each model' do
    # excluding AO because its factory has a side effect of creating a resource
    (model1, model2) = QSAId.models.reject{|m| m == ArchivalObject}

    if model1 && model2
      obj1_1 = model1.create_from_json(build("json_#{model1.my_jsonmodel.record_type}".intern))

      obj2_1 = model2.create_from_json(build("json_#{model2.my_jsonmodel.record_type}".intern))
      obj2_2 = model2.create_from_json(build("json_#{model2.my_jsonmodel.record_type}".intern))

      obj1_2 = model1.create_from_json(build("json_#{model1.my_jsonmodel.record_type}".intern))

      expect(obj1_2.qsa_id).to eq(obj1_1.qsa_id + 1)
    end
  end

end
