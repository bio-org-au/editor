require 'rails_helper'

RSpec.describe Profile::ProfileItem, type: :model do

  describe "associations" do
    it { is_expected.to belong_to(:instance) }
    it { is_expected.to belong_to(:source_profile_item).class_name('Profile::ProfileItem').optional }
    it { is_expected.to belong_to(:product_item_config).class_name('Profile::ProductItemConfig').with_foreign_key('product_item_config_id') }
    it { is_expected.to belong_to(:profile_text).class_name('Profile::ProfileText').with_foreign_key('profile_text_id') }
    it { is_expected.to belong_to(:profile_object_type).class_name('Profile::ProfileObjectType').with_primary_key('rdf_id').with_foreign_key('profile_object_rdf_id').optional }
    it { is_expected.to have_many(:profile_item_references).class_name('Profile::ProfileItemReference').with_foreign_key('profile_item_id').dependent(:destroy) }
    it { is_expected.to have_one(:product).through(:product_item_config) }
    it { is_expected.to have_one(:profile_item_annotation).class_name('Profile::ProfileItemAnnotation').with_foreign_key('profile_item_id').dependent(:destroy) }
    it { is_expected.to have_many(:sourced_in_profile_items).class_name('Profile::ProfileItem').with_foreign_key('source_profile_item_id') }
  end

  describe 'STATEMENT_TYPES constant' do
    it 'defines the correct statement types' do
      expected_types = { fact: "fact", link: "link", assertion: "assertion" }
      expect(described_class::STATEMENT_TYPES).to eq(expected_types)
    end
  end

  describe '.by_product' do
    context "for a given" do
      let!(:product) { create(:profile_product) }
      let!(:product_item_config) { create(:product_item_config, product: product) }
      let!(:item_for_product) { create(:profile_item, product_item_config: product_item_config) }

      it 'returns only profile items for the given product' do
        results = described_class.by_product(product)
        expect(results).to include(item_for_product)
      end
    end

    context "for other product" do
      let!(:product) { create(:profile_product) }
      let!(:product_item_config) { create(:product_item_config) }
      let!(:item_for_product) { create(:profile_item, product_item_config: product_item_config) }

      it 'returns only profile items for the given product' do
        results = described_class.by_product(product)
        expect(results).not_to include(item_for_product)
      end
    end

  end

  describe "#allow_delete?" do
    let(:profile_item) { create(:profile_item) }

    context "when there are no sourced_in_profile_items" do
      it "returns true" do
        expect(profile_item.allow_delete?).to be true
      end
    end

    context "when there are sourced_in_profile_items" do
      before do
        allow_any_instance_of(Name).to receive(:name_type_must_match_category).and_return(true)
        create(:profile_item, source_profile_item_id: profile_item.id, profile_object_rdf_id: profile_item.profile_object_rdf_id, product_item_config: profile_item.product_item_config)
      end

      it "returns false" do
        expect(profile_item.allow_delete?).to be false
      end
    end
  end

  describe "#fact?" do
    let!(:profile_item) { create(:profile_item) }

    context "when statement_type is 'fact'" do
      before { profile_item.update(statement_type: "fact") }

      it "returns true" do
        expect(profile_item.fact?).to be true
      end
    end

    context "when statement_type is not 'fact'" do
      before { profile_item.update(statement_type: "link") }

      it "returns false" do
        expect(profile_item.fact?).to be false
      end
    end
  end

  describe "#published?" do
    let!(:instance) { create(:instance, draft: false) }
    let!(:profile_item) { create(:profile_item, instance:) }
    let!(:tree_element) { create(:tree_element, instance:, name: instance.name) }

    before do
      profile_item.update(is_draft: false, tree_element_id: tree_element.id)
      allow(profile_item).to receive(:tree_element).and_return(tree_element)
    end

    it "returns true" do
      expect(profile_item.published?).to be true
    end

    it "returns false when is_draft is true" do
      profile_item.update(is_draft: true)
      expect(profile_item.published?).to be false
    end

    it "returns false when tree_element_id is nil" do
      profile_item.update(tree_element_id: nil)
      expect(profile_item.published?).to be false
    end
  end

  describe "#under_this_product?" do
    let!(:product) { create(:profile_product) }
    let!(:profile_item) { create(:profile_item, product_item_config: create(:product_item_config, product: product)) }
    let!(:tree_element) { create(:tree_element, instance: profile_item.instance, name: profile_item.instance.name) }

    before do
      profile_item.update(tree_element_id: tree_element.id)
      allow(profile_item).to receive(:tree_element).and_return(tree_element)
      allow(Product).to receive(:by_tree_element).with(tree_element).and_return(Product.where(id: product.id))
    end

    it "returns true when the item is under the specified product" do
      expect(profile_item.under_this_product?(product)).to be true
    end

    it "returns false when the item is not under the specified product" do
      other_product = create(:profile_product)
      expect(profile_item.under_this_product?(other_product)).to be false
    end

    it "returns false when tree_element_id is nil" do
      profile_item.update(tree_element_id: nil)
      expect(profile_item.under_this_product?(product)).to be false
    end
  end


  describe "after_destroy callback" do
    let(:profile_text) { create(:profile_text) }
    let(:profile_item) { create(:profile_item, profile_text: profile_text, statement_type: statement_type) }

    context "when the profile_item is a fact" do
      let(:statement_type) { "fact" }

      it "destroys the associated profile_text" do
        profile_item.destroy
        expect(Profile::ProfileText.exists?(profile_text.id)).to be false
      end
    end

    context "when the profile_item is not a fact" do
      let(:statement_type) { "link" }

      it "does not destroy the associated profile_text" do
        profile_item.destroy
        expect(Profile::ProfileText.exists?(profile_text.id)).to be true
      end
    end
  end
end
