# frozen_string_literal: true

require "rails_helper"

RSpec.describe("instances/tabs/_all_tab_headings.html.erb", type: :view) do
  let(:session_user) { FactoryBot.create(:session_user) }
  let(:user) { FactoryBot.create(:user) }
  let(:instance) { FactoryBot.create(:instance) }
  let(:tabs_to_offer) { [] }
  let(:product_tab_service_mock) { instance_double(Products::ProductTabService, all_available_tabs: { "instance" => [] }) }

  before do
    assign(:instance, instance)
    assign(:tabs_to_offer, tabs_to_offer)
    allow(view).to(receive(:can?).and_return(false))
    allow(view).to(receive(:increment_tab_index).and_return(1))
    allow(view).to(receive(:user_profile_tab_name).and_return("User"))

    mock_service = product_tab_service_mock
    view.define_singleton_method(:product_tab_service) { mock_service }

    assign(:current_user, session_user)
    assign(:current_registered_user, user)
    assign(:instance, instance)
    assign(:tab, "tab_show_1")

    allow(Rails.configuration).to(receive(:multi_product_tabs_enabled).and_return(false))
  end

  context "when 'tab_show_1' is offered and the user has permission" do
    before do
      tabs_to_offer << "tab_show_1"
      allow(view).to(receive(:can?).with("instances", "tab_show_1").and_return(true))
    end

    it "renders the 'Details' tab" do
      render
      expect(rendered).to(have_selector("a#instance-show-tab", text: "Details"))
    end
  end

  context "when 'tab_edit' is offered and the user has permission" do
    before do
      tabs_to_offer << "tab_edit"
      allow(view).to(receive(:can?).with(:edit, instance).and_return(true))
    end

    it "renders the 'Edit' tab" do
      render
      expect(rendered).to(have_selector("a#instance-edit-tab", text: "Edit"))
    end
  end

  context "when 'tab_edit_notes' is offered and the user has permission" do
    before do
      tabs_to_offer << "tab_edit_notes"
      allow(view).to(receive(:can?).with("instance_notes", "edit").and_return(true))
    end

    it "renders the 'Notes' tab" do
      render
      expect(rendered).to(have_selector("a#instance-edit-notes-tab", text: "Notes"))
    end
  end

  context "when 'tab_synonymy' is offered and the user has permission" do
    before do
      tabs_to_offer << "tab_synonymy"
      allow(view).to(receive(:can?).with(:create, Instance).and_return(true))
    end

    it "renders the 'Synonym' tab" do
      render
      expect(rendered).to(have_selector("a#instance-cite-this-instance-tab", text: "Syn"))
    end
  end

  context "when 'tab_unpublished_citation' is offered and the user has permission" do
    before do
      tabs_to_offer << "tab_unpublished_citation"
      allow(view).to(receive(:can?).with(:create, instance).and_return(true))
    end

    it "renders the 'Unpublished citation' tab" do
      render
      expect(rendered).to(have_selector("a#unpublished-citation-tab", text: "Unpub"))
    end
  end

  context "when 'tab_profile_v2' is offered and the user has permission" do
    before do
      tabs_to_offer << "tab_profile_v2"
      allow(view).to(receive(:can?).with(:manage_profile, instance).and_return(true))
      allow(Rails.configuration).to(receive(:profile_v2_aware).and_return(true))
    end

    it "renders the 'Profile' tab" do
      render
      expect(rendered).to(have_selector("a#instance-profile-v2-tab", text: "Profile"))
    end
  end

  context "when 'tab_batch_loader' is offered and the user has permission" do
    before do
      tabs_to_offer << "tab_batch_loader"
      allow(view).to(receive(:can?).with("loader/batches", "process").and_return(true))
    end

    it "renders the 'Batch Loader operations' tab" do
      render
      expect(rendered).to(have_selector("a#instance-batch-loader-tab", text: "Loader 1"))
    end
  end

  context "when no tabs are offered" do
    it "renders no tabs" do
      render
      expect(rendered).not_to(have_selector("a"))
    end
  end
end
