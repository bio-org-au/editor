require "rails_helper"

RSpec.describe TabsHelper, type: :helper do
  let(:product1) { instance_double(Product, name: "FOO", context_id: 1) }
  let(:product2) { instance_double(Product, name: "BAR", context_id: 2) }
  let!(:mock_product_tab_service) { instance_double(Products::ProductTabService) }
  let!(:mock_product_context_service) { instance_double(Products::ProductContextService, available_contexts: [1, 2]) }
  let(:user) do
    instance_double(
      User,
      available_product_from_roles: product1,
      available_products_from_roles: [product1, product2]
    )
  end

  before do
    allow(mock_product_tab_service).to receive(:tab_options_for).and_return({ show_product_name: true, product: product1 })
    tab_service = mock_product_tab_service
    context_service = mock_product_context_service
    test_user = user
    helper.define_singleton_method(:current_registered_user) { test_user }
    helper.define_singleton_method(:product_tab_service) { tab_service }
    helper.define_singleton_method(:product_context_service) { context_service }
    helper.define_singleton_method(:current_context_id) { 1 }
    helper.instance_variable_set(:@tab_index, nil)
    allow(Rails.configuration).to receive(:multi_product_tabs_enabled).and_return(true)
  end

  describe "#user_profile_tab_name" do
    it "returns the name of the user's available product" do
      expect(helper.user_profile_tab_name).to eq(product1.name)
    end
  end

  describe "#increment_tab_index" do
    it "increments @tab_index by 1 by default" do
      expect(helper.increment_tab_index).to eq(2)
      expect(helper.increment_tab_index).to eq(3)
    end

    it "increments @tab_index by a given value" do
      expect(helper.increment_tab_index(3)).to eq(4)
    end
  end

  describe "#tab_index" do
    it "returns @tab_index plus offset" do
      helper.increment_tab_index
      expect(helper.tab_index).to eq(2)
      expect(helper.tab_index(2)).to eq(4)
    end

    it "defaults @tab_index to 1 if not set" do
      helper.instance_variable_set(:@tab_index, nil)
      expect(helper.tab_index).to eq(1)
    end
  end

  describe '#product_tab_text' do
    let(:tab_options) { { product: product1 } }

    before do
      allow(mock_product_tab_service).to receive(:tab_options_for)
        .with(:author, 'edit')
        .and_return(tab_options)
    end

    context 'when context has multiple products providing the same tab' do
      before do
        author_service1 = instance_double(Products::ProductTabService)
        author_service2 = instance_double(Products::ProductTabService)

        allow(Products::ProductTabService).to receive(:call).with(product1).and_return(author_service1)
        allow(Products::ProductTabService).to receive(:call).with(product2).and_return(author_service2)

        allow(author_service1).to receive(:available_tabs_for).with(:author)
          .and_return([{ tab: 'edit', product: product1 }])
        allow(author_service2).to receive(:available_tabs_for).with(:author)
          .and_return([{ tab: 'edit', product: product2 }])
      end

      it 'returns product name with default text' do
        result = helper.product_tab_text(:author, 'edit', 'Edit')
        expect(result).to eq('Edit')
      end
    end

    context 'when context has only one product providing the tab' do
      it 'returns only the default text' do
        result = helper.product_tab_text(:author, 'edit', 'Edit')
        expect(result).to eq('Edit')
      end
    end

    context 'when no current context' do
      it 'returns only the default text' do
        result = helper.product_tab_text(:author, 'edit', 'Edit')
        expect(result).to eq('Edit')
      end
    end

    context 'when product is nil' do
      let(:tab_options) { { product: nil } }

      it 'handles nil product gracefully' do
        result = helper.product_tab_text(:author, 'edit', 'Edit')
        expect(result).to eq('Edit')
      end
    end

    context 'when tab_options_for returns nil' do
      before do
        allow(mock_product_tab_service).to receive(:tab_options_for)
          .with(:author, 'edit')
          .and_return(nil)
      end

      it 'returns only the default text' do
        result = helper.product_tab_text(:author, 'edit', 'Edit')
        expect(result).to eq('Edit')
      end
    end
  end

  describe '#tab_available?' do
    let(:tabs_array) { ['details', 'edit', 'comments'] }

    it 'returns true when tab is available' do
      expect(helper.tab_available?(tabs_array, 'edit')).to be true
    end

    it 'returns false when tab is not available' do
      expect(helper.tab_available?(tabs_array, 'missing_tab')).to be false
    end

    it 'handles empty tabs array' do
      expect(helper.tab_available?([], 'edit')).to be false
    end

    context "when feature flag is off" do
      before do
        allow(Rails.configuration).to receive(:multi_product_tabs_enabled).and_return(false)
      end

      it "returns true when tab is available" do
        expect(helper.tab_available?(tabs_array, 'edit')).to be true
      end

      it "returns true when tab is not available" do
        expect(helper.tab_available?(tabs_array, 'missing_tab')).to be true
      end

      it "handles empty tabs array" do
        expect(helper.tab_available?([], 'edit')).to be true
      end
    end

    context "when product contexts are empty" do
      let!(:mocked_product_context_service) { instance_double(Products::ProductContextService, available_contexts: []) }

      before do
        product_context_service = mocked_product_context_service
        helper.define_singleton_method(:product_context_service) { product_context_service }
        allow(product_context_service).to receive(:available_contexts).and_return([])
      end

      it "returns true when tab is available" do
        expect(helper.tab_available?(tabs_array, 'edit')).to be true
      end

      it "returns true when tab is not available" do
        expect(helper.tab_available?(tabs_array, 'missing_tab')).to be true
      end

      it "handles empty tabs array" do
        expect(helper.tab_available?([], 'edit')).to be true
      end
    end
  end

end
