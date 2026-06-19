# frozen_string_literal: true

require "rails_helper"

RSpec.describe "names/tabs/_tab_tag.html.erb", type: :view do
  let(:name) { create(:name) }

  before do
    allow(view).to receive(:can?).with(:manage, Name).and_return(false)
    allow(view).to receive(:can?).with(:update_common_name, name).and_return(false)
    allow(view).to receive(:increment_tab_index).and_return(1)
    stub_template "names/tabs/_tabs_row_2.html.erb" => ""
    stub_template "names/tabs/_name_tag_widgets.html.erb" => "<p>tag widgets</p>"
    assign(:name, name)
  end

  subject { render partial: "names/tabs/tab_tag" }

  context "when the user cannot edit the name" do
    it "renders no content" do
      subject
      expect(rendered.strip).to be_empty
    end
  end

  context "when the user can edit the name" do
    before { allow(view).to receive(:can?).with(:manage, Name).and_return(true) }

    context "and there are name tags" do
      before { allow(NameTag).to receive(:all).and_return(double(count: 2)) }

      it "renders the Tags heading" do
        subject
        expect(rendered).to have_selector("h5", text: "Tags")
      end

      it "renders the message containers" do
        subject
        expect(rendered).to have_selector("#search-result-details-info-message-container")
        expect(rendered).to have_selector("#search-result-details-error-message-container")
      end
    end

    context "and there are no name tags" do
      before { allow(NameTag).to receive(:all).and_return(double(count: 0)) }

      it "does not render the Tags heading" do
        subject
        expect(rendered).not_to have_selector("h5", text: "Tags")
      end

      it "still renders the message containers" do
        subject
        expect(rendered).to have_selector("#search-result-details-info-message-container")
        expect(rendered).to have_selector("#search-result-details-error-message-container")
      end
    end
  end
end
