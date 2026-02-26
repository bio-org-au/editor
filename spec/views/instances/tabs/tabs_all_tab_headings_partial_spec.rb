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
    allow(view).to(receive(:tab_available?).and_return(true))
    allow(view).to(receive(:product_tab_text) { |_entity, _tab, default| default })

    mock_service = product_tab_service_mock
    view.define_singleton_method(:product_tab_service) { mock_service }
    view.define_singleton_method(:current_product_from_context) { nil }

    assign(:current_user, session_user)
    assign(:current_registered_user, user)
    assign(:instance, instance)
    assign(:tab, "tab_show_1")

    allow(Rails.configuration).to(receive(:multi_product_tabs_enabled).and_return(false))
    allow(Rails.configuration).to(receive(:profile_edit_aware).and_return(false))
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

  context "when 'tab_edit_profile_v2' is offered and the user has permission" do
    before do
      tabs_to_offer << "tab_edit_profile_v2"
      allow(view).to(receive(:can?).with(:manage_draft_secondary_reference, instance).and_return(true))
    end

    it "renders the 'Edit' tab for profile v2" do
      render
      expect(rendered).to(have_selector("a#instance-edit-tab-profile-v2-tab", text: "Edit"))
    end
  end

  context "when 'tab_synonymy_for_profile_v2' is offered and the user has permission" do
    before do
      tabs_to_offer << "tab_synonymy_for_profile_v2"
      allow(view).to(receive(:can?).with(:synonymy_as_draft_secondary_reference, instance).and_return(true))
    end

    it "renders the 'Syn' tab for profile v2" do
      render
      expect(rendered).to(have_selector("a#instance-cite-this-instance-for-profile-v2-tab", text: "Syn"))
    end
  end

  context "when 'tab_unpublished_citation_for_profile_v2' is offered and the user has permission" do
    before do
      tabs_to_offer << "tab_unpublished_citation_for_profile_v2"
      allow(view).to(receive(:can?).with(:unpublished_citation_as_draft_secondary_reference, instance).and_return(true))
    end

    it "renders the 'Unpub' tab for profile v2" do
      render
      expect(rendered).to(have_selector("a#unpublished-citation-for-profile-v2-tab", text: "Unpub"))
    end
  end

  context "when 'tab_classification' is offered" do
    before do
      tabs_to_offer << "tab_classification"
    end

    it "renders the 'Tree' tab" do
      render
      expect(rendered).to(have_selector("a#instance-classification-tab", text: "Tree"))
    end
  end

  context "when 'tab_classification' is offered with multi_product_tabs_enabled" do
    let(:user_with_roles) { FactoryBot.create(:user) }
    let(:user_without_roles) { FactoryBot.create(:user) }

    before do
      tabs_to_offer << "tab_classification"
      allow(Rails.configuration).to(receive(:multi_product_tabs_enabled).and_return(true))
    end

    context "when current_product_from_context does not match the instance" do
      before do
        view.define_singleton_method(:current_product_from_context) { nil }
      end

      context "and user has blank roles" do
        before do
          allow(user_without_roles).to(receive(:roles).and_return([]))
          user = user_without_roles
          view.define_singleton_method(:current_registered_user) { user }
        end

        it "renders the 'Tree' tab" do
          render
          expect(rendered).to(have_selector("a#instance-classification-tab", text: "Tree"))
        end
      end

      context "and user has roles" do
        before do
          allow(user_with_roles).to(receive(:roles).and_return(["some_role"]))
          user = user_with_roles
          view.define_singleton_method(:current_registered_user) { user }
        end

        it "does not render the 'Tree' tab" do
          render
          expect(rendered).not_to(have_selector("a#instance-classification-tab"))
        end
      end
    end

    context "when current_product_from_context matches the instance" do
      let(:matching_product) { double("Product", has_the_same_reference?: true) }

      before do
        product = matching_product
        view.define_singleton_method(:current_product_from_context) { product }
        allow(user_with_roles).to(receive(:roles).and_return(["some_role"]))
        user = user_with_roles
        view.define_singleton_method(:current_registered_user) { user }
      end

      it "renders the 'Tree' tab regardless of user roles" do
        render
        expect(rendered).to(have_selector("a#instance-classification-tab", text: "Tree"))
      end
    end
  end

  context "when 'tab_comments' is offered and the user has permission" do
    before do
      tabs_to_offer << "tab_comments"
      allow(view).to(receive(:can?).with("comments", "create").and_return(true))
    end

    it "renders the 'Adnot' tab" do
      render
      expect(rendered).to(have_selector("a#instance-comments-tab", text: "Adnot"))
    end
  end

  context "when 'tab_copy_to_new_reference' is offered and the user has permission" do
    before do
      tabs_to_offer << "tab_copy_to_new_reference"
      allow(view).to(receive(:can?).with("instances", "copy_standalone").and_return(true))
    end

    it "renders the 'Copy' tab" do
      render
      expect(rendered).to(have_selector("a#instance-copy-to-new-reference-tab", text: "Copy"))
    end
  end

  context "when 'tab_copy_to_new_profile_v2' is offered and the user has permission" do
    before do
      tabs_to_offer << "tab_copy_to_new_profile_v2"
      allow(view).to(receive(:can?).with(:copy_as_draft_secondary_reference, Instance).and_return(true))
    end

    it "renders the 'Copy' tab for profile v2" do
      render
      expect(rendered).to(have_selector("a#instance-copy-to-new-profile-v2-tab", text: "Copy"))
    end
  end

  context "when 'tab_profile_details' is offered and the user has permission" do
    before do
      tabs_to_offer << "tab_profile_details"
      allow(view).to(receive(:can?).with("classification", "place").and_return(true))
    end

    it "renders the 'Profile' tab" do
      render
      expect(rendered).to(have_selector("a#instance-profile-tab", text: "Profile"))
    end
  end

  context "when 'tab_edit_profile' is offered and the user has permission" do
    before do
      tabs_to_offer << "tab_edit_profile"
      allow(Rails.configuration).to(receive(:profile_edit_aware).and_return(true))
      allow(view).to(receive(:can?).with("tree/elements", "update_profile").and_return(true))
    end

    it "renders the 'Edit Profile' tab" do
      render
      expect(rendered).to(have_selector("a#instance-edit-profile-tab", text: "Edit Profile"))
    end
  end

  context "when 'tab_batch_loader_2' is offered and the user has permission" do
    before do
      tabs_to_offer << "tab_batch_loader"
      allow(view).to(receive(:can?).with("loader/batches", "process").and_return(true))
      allow(view).to(receive(:can?).with("loader/instances-loader-2", "use").and_return(true))
    end

    it "renders the 'Loader 2' tab" do
      render
      expect(rendered).to(have_selector("a#instance-batch-loader-tab-2", text: "Loader 2"))
    end
  end

  context "when tab_available? returns false" do
    before do
      tabs_to_offer << "tab_edit"
      allow(view).to(receive(:can?).with(:edit, instance).and_return(true))
      allow(view).to(receive(:tab_available?).with(anything, "edit").and_return(false))
    end

    it "does not render the 'Edit' tab" do
      render
      expect(rendered).not_to(have_selector("a#instance-edit-tab"))
    end
  end

  context "when no tabs are offered" do
    it "renders no tabs" do
      render
      expect(rendered).not_to(have_selector("a"))
    end
  end
end
