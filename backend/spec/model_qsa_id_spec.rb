require 'spec_helper'

# don't run tests that are no longer valid because of the changes we've made
disabled_tests =
  [
   "Resources controller doesn't let you create a resource without a 4-part identifier",
   'Resource model reports an error if id_0 has no value',
   'Resource model prevents duplicate IDs ',
   'Archival Object controller allows some non-alphanumeric characters in ref_ids',
   'Archival Object controller enforces uniqueness of ref_ids within a Resource',
   'ArchivalObject model enforces ref_id uniqueness only within a resource',
   'Resource Component Transfer Endpoint returns a 400 response code when asked to transfer an object to a resource containing a conflicting object',
   'Accession model enforces ID uniqueness',
   'Accession model enforces ID max length',
   'Digital object model prevents duplicate IDs',
   'Record Suppression prevents updates to suppressed accession records',
   'Agent model returns the existing agent if an name authority id is already in place',
   'Record transfers Full repository transfers reports conflicts between the records in two repositories being merged',
   'MARCXML converter',
   'MARC Export',
   'OAI handler OAI protocol and mapping support responds to a GetRecord request for type oai_ead, mapping appropriately',
   'EAD3 export mappings',
  ]

RSpec.configure do |config|
  config.around(:each) do |example|
    example.run unless disabled_tests.include?(example.full_description)
  end
end


describe 'QSA Id model' do

  it 'generates a qsa id from a sequence on create' do
    QSAId.models.each do |model|
      obj1 = model.create_from_json(build("json_#{model.my_jsonmodel.record_type}".intern))
      obj2 = model.create_from_json(build("json_#{model.my_jsonmodel.record_type}".intern))
      expect(obj2.qsa_id).to eq(obj1.qsa_id + 1)
    end
  end


  it 'copies the generated qsa id into an existing id field if asked to' do
    QSAId.models.each do |model|
      if QSAId.existing_id_for(model)
        obj = model.create_from_json(build("json_#{model.my_jsonmodel.record_type}".intern))

        # need the jsonmodel because of four part id shenanigans
        json_id = model.my_jsonmodel.find(obj.id)[QSAId.existing_id_for(model)].to_s
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
