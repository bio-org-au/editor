require 'rails_helper'

RSpec.describe Product, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:tree).optional }
    it { is_expected.to belong_to(:reference).optional }
    it { is_expected.to have_many(:user_product_roles).class_name('User::ProductRole').through(:product_roles) }
  end

  describe '.by_tree_element' do
    let!(:instance) { create(:instance, draft: false) }
    let!(:tree) { create(:tree, is_read_only: false) }
    let!(:product) { create(:product, tree: tree) }
    let!(:tree_version) { create(:tree_version, tree: tree) }
    let!(:tree_element) { create(:tree_element, instance:, name: instance.name) }
    let!(:tree_version_element) { create(:tree_version_element, tree_version: tree_version, tree_element: tree_element) }

    it 'returns products associated with the given tree_element' do
      results = described_class.by_tree_element(tree_element)
      expect(results).to include(product)
    end

    it 'does not return products not associated with the given tree_element' do
      other_tree_element = create(:tree_element, instance:, name: instance.name)
      results = described_class.by_tree_element(other_tree_element)
      expect(results).not_to include(product)
    end

    it 'returns [] if tree_element is nil' do
      expect(described_class.by_tree_element(nil)).to be_empty
    end
  end

  describe '.with_context_and_tree' do
    let!(:context_id) { 1 }
    let!(:tree) { create(:tree) }
    let!(:product_with_tree) do
      create(:product, name: 'WithTree', context_id: context_id, tree_id: tree.id)
    end
    let!(:product_without_tree) do
      create(:product, name: 'NoTree', context_id: context_id, tree_id: nil)
    end
    let!(:product_other_context) do
      create(:product, name: 'OtherContext', context_id: 2, tree_id: tree.id)
    end

    it 'returns products with given context_id and non-nil tree_id' do
      result = Product.with_context_and_tree(context_id)
      expect(result).to include(product_with_tree)
      expect(result).not_to include(product_without_tree)
      expect(result).not_to include(product_other_context)
    end
  end
end

