require 'spec_helper'

describe 'Runcorn Charges' do
  describe 'ChargeableItem model' do

    let!(:chargeable_item) do
      ChargeableItem.create_from_json(build(:json_chargeable_item))
    end

    it 'has some properties' do
      dollar_store = ChargeableItem.create_from_json(build(:json_chargeable_item,
                                                           :price_cents => 100,
                                                           :name => 'dollar thing',
                                                           :description => 'So Cheap!',
                                                           :charge_quantity_unit => 'order'))

      json = ChargeableItem.to_jsonmodel(dollar_store.id)

      expect(json['name']).to eq('dollar thing')
      expect(json['price_dollars']).to eq('$1.00')
      expect(json['description']).to eq('So Cheap!')
      expect(json['charge_quantity_unit']).to eq('order')
    end


    it 'allows updating price_cents from price_dollars' do
      json = ChargeableItem.to_jsonmodel(chargeable_item.id)
      json['price_dollars'] = '$99.99'
      chargeable_item.update_from_json(json)

      chargeable_item.refresh
      expect(chargeable_item.price_cents).to eq(9999)
    end

  end
end
