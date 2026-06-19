# frozen_string_literal: true

require "rails_helper"

RSpec.describe "names/tabs/_tabs_row_2.html.erb", type: :view do
  let(:name) { create(:name) }
  let(:product_tab_service_mock) do
    instance_double(Products::ProductTabService, all_available_tabs: { "name" => [] })
  end

  before do
    allow(view).to receive(:can?).with(:manage, Name).and_return(false)
    allow(view).to receive(:can?).with(:update_common_name, name).and_return(false)
    allow(view).to receive(:can?).with("names", "update").and_return(false)
    allow(view).to receive(:increment_tab_index).and_return(1)
    allow(NameTag).to receive(:all).and_return(double(count: 0))

    mock_service = product_tab_service_mock
    view.define_singleton_method(:product_tab_service) { mock_service }

    assign(:name, name)
    assign(:tab, "tab_show_1")
    allow(Rails.configuration).to receive(:multi_product_tabs_enabled).and_return(false)
  end

  subject { render partial: "names/tabs/tabs_row_2" }

  context "when the user cannot edit the name" do
    it "does not render the Comment tab" do
      subject
      expect(rendered).not_to have_link("Comment", id: "name-comment-tab")
    end

    it "does not render the Tag tab" do
      subject
      expect(rendered).not_to have_link("Tag", id: "name-tags-tab")
    end

    it "does not render the Refresh tab" do
      subject
      expect(rendered).not_to have_link("Refresh", id: "name-refresh-tab")
    end
  end

  context "when the user can edit the name" do
    before { allow(view).to receive(:can?).with(:manage, Name).and_return(true) }

    it "renders the Comment tab" do
      subject
      expect(rendered).to have_link("Comment", id: "name-comment-tab")
    end

    it "renders the Refresh tab" do
      subject
      expect(rendered).to have_link("Refresh", id: "name-refresh-tab")
    end

    context "and there are name tags" do
      before { allow(NameTag).to receive(:all).and_return(double(count: 1)) }

      it "renders the Tag tab" do
        subject
        expect(rendered).to have_link("Tag", id: "name-tags-tab")
      end
    end

    context "and there are no name tags" do
      it "does not render the Tag tab" do
        subject
        expect(rendered).not_to have_link("Tag", id: "name-tags-tab")
      end
    end
  end

  context "de-duplicate tab" do
    context "when the name is a duplicate and user can update names" do
      before do
        allow(name).to receive(:duplicate?).and_return(true)
        allow(view).to receive(:can?).with("names", "update").and_return(true)
      end

      it "renders the De-duplicate tab" do
        subject
        expect(rendered).to have_link("De-duplicate", id: "name-de-duplicate-tab")
      end
    end

    context "when the name is a duplicate but user cannot update names" do
      before do
        allow(name).to receive(:duplicate?).and_return(true)
      end

      it "does not render the De-duplicate tab" do
        subject
        expect(rendered).not_to have_link("De-duplicate", id: "name-de-duplicate-tab")
      end
    end

    context "when the name is not a duplicate" do
      before do
        allow(name).to receive(:duplicate?).and_return(false)
        allow(view).to receive(:can?).with("names", "update").and_return(true)
      end

      it "does not render the De-duplicate tab" do
        subject
        expect(rendered).not_to have_link("De-duplicate", id: "name-de-duplicate-tab")
      end
    end
  end
end
