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

  describe ".drafts" do
    let(:instance) { create(:instance, draft: false) }
    let!(:product_item_config) { create(:product_item_config) }
    let(:draft_item) { create(:profile_item, product_item_config:, instance:, is_draft: true) }
    let(:published_item) { create(:profile_item, product_item_config:, instance:, is_draft: false) }

    subject { described_class.drafts }

    it 'returns only draft profile items' do
      expect(subject).to include(draft_item)
    end

    it "excludes non-draft profile items" do
      expect(subject).not_to include(published_item)
    end
  end

  describe ".by_product_item_config" do
    let(:instance) { create(:instance) }
    let!(:profile_item_type) { create(:profile_item_type) }
    let!(:product_item_config1) { create(:product_item_config, profile_item_type:) }
    let!(:product_item_config2) { create(:product_item_config, profile_item_type:) }
    let!(:profile_item1) { create(:profile_item, product_item_config: product_item_config1, instance:) }
    let!(:profile_item2) { create(:profile_item, product_item_config: product_item_config2, instance:) }

    it 'returns only profile items for the given product item config' do
      results = described_class.by_product_item_config(product_item_config1)
      expect(results).to include(profile_item1)
      expect(results).not_to include(profile_item2)
    end
  end

  describe '.by_product' do
    context "for a given" do
      let!(:product) { create(:product) }
      let!(:product_item_config) { create(:product_item_config, product: product) }
      let!(:item_for_product) { create(:profile_item, product_item_config: product_item_config) }

      it 'returns only profile items for the given product' do
        results = described_class.by_product(product)
        expect(results).to include(item_for_product)
      end
    end

    context "for other product" do
      let!(:product) { create(:product) }
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
    let!(:product) { create(:product) }
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
      other_product = create(:product)
      expect(profile_item.under_this_product?(other_product)).to be false
    end

    it "returns false when tree_element_id is nil" do
      profile_item.update(tree_element_id: nil)
      expect(profile_item.under_this_product?(product)).to be false
    end
  end

  describe "#draft_version?" do
    let(:profile_item) { create(:profile_item, instance: instance, is_draft: true) }

    subject { profile_item.draft_version? }

    context "when instance is draft" do
      let(:instance) { create(:instance, draft: true) }

      context "and profile item is a draft" do
        it "returns false" do
          expect(subject).to be false
        end
      end

      context "and profile item is not a draft" do
        before { profile_item.update(is_draft: false) }
        it "returns false" do
          expect(subject).to be false
        end
      end
    end

    context "when instance is not draft" do
      let(:instance) { create(:instance, draft: false) }

      context "and profile item is a draft" do
        it "returns true" do
          expect(subject).to be true
        end
      end

      context "and profile item is not a draft" do
        before { profile_item.update(is_draft: false) }
        it "returns false" do
          expect(subject).to be false
        end
      end
    end
  end

  describe "#publish!" do
    let(:instance) { create(:instance, draft: false) }
    let(:profile_item) { create(:profile_item, instance:, is_draft: true, published_date: nil ) }

    subject { profile_item.publish! }

    it "sets is_draft to false and updates the tree_element_id" do
      expect { subject }.to change { profile_item.is_draft }.from(true).to(false)
    end

    it "returns true" do
      expect(subject).to be true
    end

    it "updates the published_date" do
      expect { subject }.to change { profile_item.published_date }.from(nil).to be_within(1.second).of(Time.current)
    end

    context "when already published" do
      let(:profile_item) { create(:profile_item, is_draft: false, published_date: Time.current - 30.days ) }

      it "does not change is_draft or published_date" do
        expect { subject }.not_to change { profile_item.is_draft }
        expect { subject }.not_to change { profile_item.published_date }
      end
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
