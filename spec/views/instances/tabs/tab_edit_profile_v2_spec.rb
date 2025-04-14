require 'rails_helper'

RSpec.describe "instances/tabs/_tab_edit_profile_v2.html.erb", type: :view do
  let(:language) { FactoryBot.create(:language, iso6391code: "en", iso6393code: "eng") }
  let(:reference) { FactoryBot.create(:reference, language: language) }
  let(:instance_type) { FactoryBot.create(:instance_type, secondary_instance: false)}
  let(:instance) { FactoryBot.create(:instance, reference: reference) }

  before do
    assign(:instance, instance)
    allow(view).to receive(:increment_tab_index).and_return(0)
    allow(view).to receive(:divider).and_return("<hr>".html_safe)
  end

  context "when the user can manage draft secondary references" do
    before do
      allow(view).to receive(:can?).with(:manage_draft_secondary_reference, instance).and_return(true)
      allow(ShardConfig).to receive(:classification_tree_key).and_return("some_value")
      allow(ShardConfig).to receive(:name_space).and_return("some_value")
      allow_any_instance_of(Name).to receive(:accepted_concept?).and_return(false)
      allow_any_instance_of(Name).to receive(:excluded_concept?).and_return(false)
      allow(Tree).to receive_message_chain(:accepted, :first, :current_tree_version).and_return(double("TreeVersion", id: 1, name_in_version: "Test"))
    end

    context "when the instance allows deletion" do
      before do
        allow(instance).to receive(:allow_delete?).and_return(true)
      end

      it "renders the delete widgets" do
        render
        expect(rendered).to render_template(partial: "instances/tabs/_show_standalone")
        expect(rendered).to render_template("instances/_delete_widgets")
        expect(rendered).not_to render_template("instances/widgets/_no_delete_reasons")
      end
    end

    context "when the instance does not allow deletion" do
      before do
        allow(instance).to receive(:allow_delete?).and_return(false)
      end

      it "renders the no delete reasons widget" do
        render
        expect(rendered).to render_template(partial: "instances/tabs/_show_standalone")
        expect(rendered).to render_template("instances/widgets/_no_delete_reasons")
        expect(rendered).not_to render_template("delete_widgets")
      end
    end
  end

  context "when the user cannot manage draft secondary references" do
    before do
      allow(view).to receive(:can?).with(:manage_draft_secondary_reference, instance).and_return(false)
    end

    it "does not render the edit tab" do
      render
      expect(rendered).not_to have_selector("a#instance-edit-tab-profile-v2-tab", text: "Edit")
    end
  end
end
