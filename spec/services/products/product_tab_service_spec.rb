require 'rails_helper'

RSpec.describe Products::ProductTabService do
  let(:config) { Products::ProductTabConfig.new }
  let(:context_1) { 1 }
  let(:context_2) { 2 }
  let(:product_no_flags) do
    instance_double(
      Product,
      id: 1,
      is_name_index: false,
      has_default_reference: false,
      manages_taxonomy: false,
      manages_profile: false
    )
  end
  let(:product_with_name_index) do
    instance_double(
      Product,
      id: 2,
      is_name_index: true,
      has_default_reference: false,
      manages_taxonomy: false,
      manages_profile: false,
      context_id: 1
    )
  end
  let(:product_with_default_reference) do
    instance_double(
      Product,
      id: 3,
      is_name_index: false,
      has_default_reference: true,
      manages_taxonomy: false,
      manages_profile: false,
      context_id: 1
    )
  end
  let(:product_with_multiple_flags) do
    instance_double(
      Product,
      id: 4,
      is_name_index: true,
      has_default_reference: true,
      manages_taxonomy: false,
      manages_profile: false,
      context_id: 2
    )
  end
  let(:product_name_only) do
    instance_double(
      Product,
      id: 5,
      is_name_index: true,
      has_default_reference: false,
      manages_taxonomy: false,
      manages_profile: false
    )
  end
  let(:product_reference_only) do
    instance_double(
      Product,
      id: 6,
      is_name_index: false,
      has_default_reference: true,
      manages_taxonomy: false,
      manages_profile: false
    )
  end
  let(:product_with_manages_taxonomy) do
    instance_double(
      Product,
      id: 7,
      is_name_index: false,
      has_default_reference: false,
      manages_taxonomy: true,
      manages_profile: false,
      context_id: 1
    )
  end
  let(:product_with_manages_profile) do
    instance_double(
      Product,
      id: 8,
      is_name_index: false,
      has_default_reference: false,
      manages_taxonomy: false,
      manages_profile: true
    )
  end
  let(:product_with_all_flags) do
    instance_double(
      Product,
      id: 9,
      is_name_index: true,
      has_default_reference: true,
      manages_taxonomy: true,
      manages_profile: true
    )
  end

  let!(:products) do
    [
      product_no_flags,
      product_with_name_index,
      product_with_default_reference,
      product_with_multiple_flags,
      product_name_only,
      product_reference_only,
      product_with_manages_taxonomy,
      product_with_manages_profile,
      product_with_all_flags
    ]
  end

  subject { described_class.call(products) }

  describe ".for_context" do
    it "returns a service instance for the given context" do
      service = described_class.for_context(context_1)
      expect(service).to be_a(described_class)
      expect(service.context_id).to eq(context_1)
    end
  end

  describe ".products_for_context" do
    it "returns the product context for the given context id" do
      allow(Product).to receive(:where).with(context_id: context_1).and_return([
        product_with_name_index,
        product_with_default_reference,
        product_with_manages_taxonomy
      ])

      products = described_class.products_for_context(context_1)
      expect(products).to match_array([
        product_with_name_index,
        product_with_default_reference,
        product_with_manages_taxonomy
      ])
    end

    it "returns empty array for nil context id" do
      products = described_class.products_for_context(-1)
      expect(products).to eq([])
    end
  end

  describe "#execute" do
    it "has the correct active_flags" do
      subject
      expect(subject.active_flags).to match_array(["is_name_index", "has_default_reference", "manages_taxonomy", "manages_profile"])
    end

    it "has enabled_models" do
      subject
      expect(subject.enabled_models).to match_array(["author", "instance", "name", "profile", "reference"])
    end

    it "has products" do
      subject
      expect(subject.products).to match_array(products)
    end

    context "when no products are provided" do
      let!(:products) { [] }

      it "has no active_flags" do
        subject
        expect(subject.active_flags).to be_empty
      end

      it "has no enabled_models" do
        subject
        expect(subject.enabled_models).to be_empty
      end
    end

    context "when passing a single product in the array" do
      let!(:products) { [product_with_name_index] }

      it "has the correct active_flags" do
        subject
        expect(subject.active_flags).to match_array(["is_name_index"])
      end

      it "has enabled_models" do
        subject
        expect(subject.enabled_models).to match_array(["author", "instance", "name", "profile", "reference"])
      end

      it "has products" do
        subject
        expect(subject.products).to match_array(products)
      end
    end
  end

  describe '#all_available_tabs' do
    it "returns a hash of all enabled model tabs based on flags" do
      result = subject.all_available_tabs

      expect(result).to be_a(Hash)
    end

    it "returns all available tabs for the product" do
      result = subject.all_available_tabs
      expect(result).to include("author")
      expect(result).to include("instance")
      expect(result).to include("name")
      expect(result).to include("profile")
      expect(result).to include("reference")
    end

    context "when passing and empty product array" do
      let!(:products) { [] }

      it "returns an empty hash" do
        result = subject.all_available_tabs
        expect(result).to eq({})
      end
    end
  end

  describe "#tabs_per_product" do
    it "returns a hash mapping each product to its respective models and tabs" do
      result = subject.tabs_per_product
      expect(result).to be_a(Hash)
    end

    it "returns all available tabs for each product" do
      result = subject.tabs_per_product
      expect(result).to be_a(Hash)
      expect(result).to include(product_with_name_index)
      expect(result).to include(product_with_default_reference)
    end

    context "with single product having is_name_index flag" do
      let!(:products) { [product_with_name_index] }

      it 'returns hash mapping product to its models and tabs' do
        result = subject.tabs_per_product

        expect(result).to have_key(product_with_name_index)
        expect(result[product_with_name_index]).to have_key("author")
        expect(result[product_with_name_index]).to have_key("reference")
        expect(result[product_with_name_index]["author"]).to eq(["new", "details", "edit", "comments"])
        expect(result[product_with_name_index]["reference"]).to eq(["new", "details", "edit_1", "edit_2", "edit_3", "comments", "new_instance", "copy"])
      end
    end

    context "with single product having has_default_reference flag" do
      let!(:products) { [product_with_default_reference] }

      it 'returns hash mapping product to its models and tabs' do
        result = subject.tabs_per_product

        expect(result).to have_key(product_with_default_reference)
        expect(result[product_with_default_reference]).to have_key("author")
        expect(result[product_with_default_reference]).to have_key("reference")
        expect(result[product_with_default_reference]["author"]).to eq(["details"])
        expect(result[product_with_default_reference]["reference"]).to eq(["details"])
      end
    end

    context "with multiple products having different flags" do
      let!(:products) { [product_name_only, product_reference_only] }
      it 'returns hash mapping each product to its respective models and tabs' do
        result = subject.tabs_per_product

        expect(result).to have_key(product_name_only)
        expect(result).to have_key(product_reference_only)

        expect(result[product_name_only]["author"]).to eq(["new", "details", "edit", "comments"])
        expect(result[product_name_only]["reference"]).to eq(["new", "details", "edit_1", "edit_2", "edit_3", "comments", "new_instance", "copy"])

        expect(result[product_reference_only]["author"]).to eq(["details"])
        expect(result[product_reference_only]["reference"]).to eq(["details"])
      end
    end

    context "with product having no flags" do
      let!(:products) { [product_no_flags] }

      it "returns empty hash for product" do
        result = subject.tabs_per_product

        expect(result).to have_key(product_no_flags)
        expect(result[product_no_flags]).to eq({})
      end
    end

    context "with product having multiple flags" do
      let!(:products) { [product_with_multiple_flags] }

      it "returns combined tabs for the product" do
        result = subject.tabs_per_product

        expect(result).to have_key(product_with_multiple_flags)
        expect(result[product_with_multiple_flags]["author"]).to eq(["new", "details", "edit", "comments"])
        expect(result[product_with_multiple_flags]["reference"]).to eq(["new", "details", "edit_1", "edit_2", "edit_3", "comments", "new_instance", "copy"])
      end
    end
  end

  describe "#tab_options_for" do
    let!(:products) { [product_with_name_index, product_with_default_reference] }
    it "returns the tab for the given model and tab name" do
      result = subject.tab_options_for(:author, :new)

      expect(result).to be_a(Hash)
      expect(result[:tab]).to eq("new")
      expect(result[:product]).to eq(product_with_name_index)
    end

    context "when no tab exists" do
      it "returns nil" do
        result = subject.tab_options_for(:author, :non_existing)

        expect(result).to be_nil
      end
    end
  end
end
