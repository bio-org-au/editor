# frozen_string_literal: true

require "rails_helper"

RSpec.describe "names/tabs/_tab_more.html.erb", type: :view do
  let(:name) { create(:name) }
  let(:product_tab_service_mock) do
    instance_double(Products::ProductTabService, all_available_tabs: { "name" => [] })
  end

  before do
    allow(view).to receive(:can?).with(:manage, Name).and_return(false)
    allow(view).to receive(:can?).with(:update_common_name, name).and_return(false)
    allow(view).to receive(:increment_tab_index).and_return(1)
    stub_template "names/tabs/_tabs_row_2.html.erb" => '<div id="tabs-row-2-stub"></div>'
    stub_template "names/tabs/_tab_comments.html.erb" => '<div id="tab-comments-stub">comments</div>'

    mock_service = product_tab_service_mock
    view.define_singleton_method(:product_tab_service) { mock_service }

    assign(:name, name)
    allow(Rails.configuration).to receive(:multi_product_tabs_enabled).and_return(false)
  end

  subject { render partial: "names/tabs/tab_more" }

  context "when the user cannot edit the name" do
    it "renders no content" do
      subject
      expect(rendered.strip).to be_empty
    end
  end

  context "when the user can edit the name" do
    before { allow(view).to receive(:can?).with(:manage, Name).and_return(true) }

    it "renders the tabs_row_2 partial" do
      subject
      expect(rendered).to have_selector("#tabs-row-2-stub")
    end

    context "and the more_comment tab is available" do
      let(:product_tab_service_mock) do
        instance_double(Products::ProductTabService, all_available_tabs: { "name" => [{ tab: "more_comment" }] })
      end

      it "renders the tab_comments partial" do
        subject
        expect(rendered).to have_selector("#tab-comments-stub")
      end
    end

    context "and the more_comment tab is not configured" do
      before do
        allow(Rails.configuration).to receive(:multi_product_tabs_enabled).and_return(true)
        mock_context_service = instance_double(Products::ProductContextService, available_contexts: [1])
        view.define_singleton_method(:product_context_service) { mock_context_service }
      end

      it "does not render the tab_comments partial" do
        subject
        expect(rendered).not_to have_selector("#tab-comments-stub")
      end
    end
  end
end
