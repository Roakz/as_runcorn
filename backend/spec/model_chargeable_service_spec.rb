require 'spec_helper'

describe 'Runcorn Charges' do
  describe 'ChargeableService model' do

    it 'has some properties' do
      call_out = ChargeableItem.create_from_json(build(:json_chargeable_item,
                                                       :price_cents => 5000,
                                                       :description => 'You call, we come',
                                                       :charge_quantity_unit => 'order'))

      chlorine = ChargeableItem.create_from_json(build(:json_chargeable_item,
                                                       :price_cents => 1995,
                                                       :description => 'Kill the bugs',
                                                       :charge_quantity_unit => 'record'))

      work = ChargeableItem.create_from_json(build(:json_chargeable_item,
                                                   :price_cents => 300,
                                                   :description => 'Minimum wage mofos',
                                                   :charge_quantity_unit => 'qtr_hour'))

      items = [
               {'ref' => call_out.uri},
               {'ref' => chlorine.uri},
               {'ref' => work.uri},
              ]

      pool_cleaning = ChargeableService.create_from_json(build(:json_chargeable_service,
                                                               :name => 'Pool Cleaning Service',
                                                               :description => 'We clean your pool!',
                                                               :service_items => items))

      json = URIResolver.resolve_references(ChargeableService.to_jsonmodel(pool_cleaning.id), ['service_items'])

      expect(json['name']).to eq('Pool Cleaning Service')
      expect(json['description']).to eq('We clean your pool!')
      expect(json['service_items'].length).to eq(3)
      expect(json['service_items'].first['_resolved']['price_dollars']).to eq('$50.00')
    end
  end
end
