require 'spec_helper'

describe 'Runcorn Charges' do
  describe 'ServiceQuote model' do

    let(:call_out) do
      ChargeableItem.create_from_json(build(:json_chargeable_item,
                                            :price_cents => 5000,
                                            :description => 'You call, we come',
                                            :charge_quantity_unit => 'order'))
    end

    let(:chlorine) do
      ChargeableItem.create_from_json(build(:json_chargeable_item,
                                            :price_cents => 1995,
                                            :description => 'Kill the bugs',
                                            :charge_quantity_unit => 'record'))
    end

    let(:work) do
      ChargeableItem.create_from_json(build(:json_chargeable_item,
                                            :price_cents => 300,
                                            :description => 'Minimum wage mofos',
                                            :charge_quantity_unit => 'qtr_hour'))
    end

    let(:pool_cleaning) do
      ChargeableService.create_from_json(build(:json_chargeable_service,
                                               :name => 'Pool Cleaning Service',
                                               :description => 'We clean your pool!',
                                               :service_items => [{'ref' => call_out.uri},
                                                                  {'ref' => chlorine.uri},
                                                                  {'ref' => work.uri}]))
    end


    it 'can calculate a total charge' do

      items = [
               {
                 'quantity' => 1,
                 'chargeable_item' => {
                   'ref' => call_out.uri
                 }
               },
               {
                 'quantity' => 3,
                 'chargeable_item' => {
                   'ref' => chlorine.uri
                 }
               },
               {
                 'quantity' => 8,
                 'chargeable_item' => {
                   'ref' => work.uri
                 }
               }
              ]

      we_cleaned_your_pool = ServiceQuote.create_from_json(build(:json_service_quote,
                                                                 :chargeable_service => {'ref' => pool_cleaning.uri},
                                                                 :line_items => items))

      json = URIResolver.resolve_references(ServiceQuote.to_jsonmodel(we_cleaned_your_pool.id), ['chargeable_item'])

      expect(json['total_charge_cents']).to eq(13385)
    end
  end
end
