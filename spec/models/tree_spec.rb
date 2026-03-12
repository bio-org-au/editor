# frozen_string_literal: true

require "rails_helper"

RSpec.describe Tree, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:default_draft_version).class_name("TreeVersion").optional }
    it { is_expected.to belong_to(:current_tree_version).class_name("TreeVersion").optional }
    it { is_expected.to have_many(:tree_versions) }
    it { is_expected.to have_many(:products) }
    it { is_expected.to have_many(:user_product_role_vs) }
  end

  describe ".menu_drafts" do
    context "when tree has unpublished draft version" do
      let(:tree_with_draft) { create(:tree, name: "TreeWithDraft", is_read_only: false, accepted_tree: true) }
      let(:draft_version) { create(:tree_version, tree: tree_with_draft, published: false, draft_name: "Draft 1", log_entry: "Log entry 1") }

      before { draft_version }

      it "returns trees with unpublished draft versions" do
        results = described_class.menu_drafts
        expect(results.pluck(:name)).to include("TreeWithDraft")
      end

      it "includes draft_id in the result" do
        results = described_class.menu_drafts
        tree_result = results.find { |r| r.name == "TreeWithDraft" }
        expect(tree_result.draft_id).to eq(draft_version.id)
      end

      it "includes draft_name in the result" do
        results = described_class.menu_drafts
        tree_result = results.find { |r| r.name == "TreeWithDraft" }
        expect(tree_result.draft_name).to eq("Draft 1")
      end

      it "includes log_entry in the result" do
        results = described_class.menu_drafts
        tree_result = results.find { |r| r.name == "TreeWithDraft" }
        expect(tree_result.log_entry).to eq("Log entry 1")
      end

      it "includes accepted_tree in the result" do
        results = described_class.menu_drafts
        tree_result = results.find { |r| r.name == "TreeWithDraft" }
        expect(tree_result.accepted_tree).to be true
      end
    end

    context "when tree only has published versions" do
      let(:tree_without_draft) { create(:tree, name: "TreeWithoutDraft", is_read_only: false, accepted_tree: false) }
      let(:published_version) { create(:tree_version, tree: tree_without_draft, published: true) }

      before { published_version }

      it "excludes trees that only have published versions" do
        results = described_class.menu_drafts
        expect(results.pluck(:name)).not_to include("TreeWithoutDraft")
      end
    end

    context "when tree is read-only" do
      let(:read_only_tree) { create(:tree, name: "ReadOnlyTree", is_read_only: false, accepted_tree: true) }
      let(:read_only_draft) { create(:tree_version, tree: read_only_tree, published: false) }

      before do
        read_only_draft
        read_only_tree.update!(is_read_only: true)
      end

      it "excludes read-only trees" do
        results = described_class.menu_drafts
        expect(results.pluck(:name)).not_to include("ReadOnlyTree")
      end
    end

    context "when ordering results" do
      let(:tree_b) { create(:tree, name: "BTree", is_read_only: false) }
      let(:tree_a) { create(:tree, name: "ATree", is_read_only: false) }
      let(:draft_b) { create(:tree_version, tree: tree_b, published: false) }
      let(:draft_a) { create(:tree_version, tree: tree_a, published: false) }

      before do
        draft_b
        draft_a
      end

      it "orders results by tree name" do
        results = described_class.menu_drafts
        names = results.pluck(:name)
        expect(names).to eq(names.sort)
      end
    end
  end

  describe "#read_only?" do
    it "returns true when is_read_only is true" do
      tree = build(:tree, is_read_only: true)
      expect(tree.read_only?).to be true
    end

    it "returns false when is_read_only is false" do
      tree = build(:tree, is_read_only: false)
      expect(tree.read_only?).to be false
    end
  end

  describe "#config?" do
    it "returns true when config is present" do
      tree = build(:tree, config: {"key" => "value"})
      expect(tree.config?).to be true
    end

    it "returns false when config is nil" do
      tree = build(:tree, config: nil)
      expect(tree.config?).to be false
    end

    it "returns false when config is empty" do
      tree = build(:tree, config: {})
      expect(tree.config?).to be false
    end
  end

  describe "#comment_key" do
    it "returns the comment_key from config" do
      tree = build(:tree, config: {"comment_key" => "APC Comment"})
      expect(tree.comment_key).to eq("APC Comment")
    end

    it "returns nil when comment_key is not in config" do
      tree = build(:tree, config: {})
      expect(tree.comment_key).to be_nil
    end
  end

  describe "#distribution_key" do
    it "returns the distribution_key from config" do
      tree = build(:tree, config: {"distribution_key" => "APC Dist."})
      expect(tree.distribution_key).to eq("APC Dist.")
    end

    it "returns nil when distribution_key is not in config" do
      tree = build(:tree, config: {})
      expect(tree.distribution_key).to be_nil
    end
  end

  describe "#holds_profile_data?" do
    it "returns true when config is present" do
      tree = build(:tree, config: {"key" => "value"})
      expect(tree.holds_profile_data?).to be true
    end

    it "returns false when config is not present" do
      tree = build(:tree, config: nil)
      expect(tree.holds_profile_data?).to be false
    end
  end

  describe "#has_no_drafts?" do
    context "when tree has no unpublished versions" do
      let(:tree) { create(:tree, name: "NoDraftTree", is_read_only: false) }
      let(:published_version) { create(:tree_version, tree: tree, published: true) }

      it "returns true" do
        published_version
        expect(tree.has_no_drafts?).to be true
      end
    end

    context "when tree has unpublished versions" do
      let(:tree) { create(:tree, name: "HasDraftTree", is_read_only: false) }
      let(:draft_version) { create(:tree_version, tree: tree, published: false) }

      it "returns false" do
        draft_version
        expect(tree.has_no_drafts?).to be false
      end
    end

    context "when tree has no versions" do
      let(:tree) { create(:tree, name: "NoVersionTree", is_read_only: false) }

      it "returns true" do
        expect(tree.has_no_drafts?).to be true
      end
    end
  end
end
