require 'rails_helper'

RSpec.describe Instance::AsTypeahead::ForProductItemConfig, type: :model do
  describe '#initialize' do
    let(:term) { 'example' }

    context 'when product_item_config_id is blank' do
      it 'sets @instances to an empty array' do
        result = described_class.new(product_item_config_id: nil, term: term)
        expect(result.instances).to eq([])
      end
    end

    context 'when product_item_config_id is present' do
      let!(:instance) { create(:instance, draft: false) }
      let!(:profile_item) { create(:profile_item, instance: instance, is_draft: false) }

      context "when there's a matching term" do
        let(:term) { instance.reference.citation[1..3] }

        it 'returns instances matching the term' do
          result = described_class.new(product_item_config_id: profile_item.product_item_config_id, term: term)
          expect(result.instances).not_to be_empty
        end

        it 'returns instances matching the full name' do
          result = described_class.new(product_item_config_id: profile_item.product_item_config_id, term: instance.name.full_name)
          expect(result.instances).not_to be_empty
        end

        it 'returns instance matching the full name with foreign characters' do
          name = instance.name
          name.update(full_name: 'Céllerius')
          result = described_class.new(product_item_config_id: profile_item.product_item_config_id, term: 'cellerius')
          expect(result.instances).not_to be_empty
        end

        it "returns a correct array format" do
          result = described_class.new(product_item_config_id: profile_item.product_item_config_id, term: term)
          expect(result.instances).to all(include(:value, :id, :profile_item_id))
        end

        it  'returns an empty array if instance is draft' do
          instance.update(draft: true)
          result = described_class.new(product_item_config_id: profile_item.product_item_config_id, term: term)
          expect(result.instances).to be_empty
        end

        it "returns an empty array if profile_item is draft" do
          profile_item.update(is_draft: true)
          result = described_class.new(product_item_config_id: profile_item.product_item_config_id, term: term)
          expect(result.instances).to be_empty
        end

      end

      context "when there's no matching term" do
        let(:term) { 'non_matching_term' }

        it 'returns an empty array' do
          result = described_class.new(product_item_config_id: profile_item.product_item_config_id, term: term)
          expect(result.instances).to be_empty
        end
      end
    end

  end
end
