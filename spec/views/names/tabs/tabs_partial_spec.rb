require 'rails_helper'

RSpec.describe "names/tabs/_tabs.html.erb", type: :view do
  let(:user) { FactoryBot.create(:session_user) }
  let(:name) { FactoryBot.create(:name) }

  before do
    allow(view).to receive(:can?).with('instances', 'create').and_return(false)
    allow(view).to receive(:can?).with('names', 'update').and_return(false)
    allow(view).to receive(:can?).with('names', 'delete').and_return(false)
    allow(view).to receive(:increment_tab_index).and_return(1)

    assign(:current_user, user)
    assign(:tab, "tab_show_1")
    assign(:name, name)
  end

  subject { render partial: "names/tabs/tabs" }

  it "renders the Details tab" do
    subject
    expect(rendered).to have_selector("ul.nav.nav-tabs")
    expect(rendered).to have_link("Details", id: "name-details-tab" )
  end

  it "does not render the Edit tab" do
    subject
    expect(rendered).not_to have_link('Edit', id: 'name-edit-tab')
  end

  it "does not render the Delete tab" do
    subject
    expect(rendered).not_to have_link('Delete name', id: 'name-delete-tab')
  end

  it "does not render the New instance tab" do
    subject
    expect(rendered).not_to have_link('New instance', id: 'name-instances-profile-v2-tab')
    expect(rendered).not_to have_link('New instance', id: 'name-instances-tab')
  end

  context "when the user can update names" do
    before do
      allow(view).to receive(:can?).with('names', 'update').and_return(true)
    end

    it "renders the Edit tab" do
      subject
      expect(rendered).to have_link('Edit', id: 'name-edit-tab')
    end
  end

  context "when a user can create an instance" do
    before do
      allow(view).to receive(:can?).with('instances', 'create').and_return(true)
    end

    context "and it has new_instance_allowed? set to true" do
      before do
        allow(user).to receive_message_chain(:profile_v2_context, :new_instance_allowed?).and_return(true)
      end

      it "renders the New instance profile v2 tab" do
        subject
        expect(rendered).to have_link('New instance', id: 'name-instances-profile-v2-tab')
      end

      it "does not render the regular New instance tab" do
        subject
        expect(rendered).not_to have_link('New instance', id: 'name-instances-tab')
      end
    end

    context "and it has new_instance_allowed? set to false" do
      it "does not render the New instance profile v2 tab" do
        subject
        expect(rendered).not_to have_link('New instance', id: 'name-instances-profile-v2-tab')
      end

      it "renders the regular New instance tab" do
        subject
        expect(rendered).to have_link('New instance', id: 'name-instances-tab')
      end
    end
  end

  context "when a user can update a name" do
    before do
      allow(view).to receive(:can?).with('names', 'update').and_return(true)
    end

    it "renders the Edit tab" do
      subject
      expect(rendered).to have_link('Edit', id: 'name-edit-tab')
    end
  end

  context "when a user can delete a name" do
    before do
      allow(view).to receive(:can?).with('names', 'delete').and_return(true)
    end

    it "does not render the Delete tab" do
      subject
      expect(rendered).to have_link('Delete name', id: 'name-delete-tab')
    end
  end
end
