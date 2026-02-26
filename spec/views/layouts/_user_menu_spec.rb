require "rails_helper"

RSpec.describe "layouts/_user_menu.html.erb", type: :view do
  let(:session_user) { FactoryBot.create(:session_user) }
  let(:registered_user) { FactoryBot.create(:user, user_name: "Registered User") }
  let!(:role) { FactoryBot.create(:role) }
  let!(:product) { FactoryBot.create(:product, name: "Product") }
  let(:product_role) { FactoryBot.create(:product_role, product:, role:) }
  let!(:user_product_role) { FactoryBot.create(:user_product_role, product_role:, user: registered_user) }

  before do
    allow(view).to receive(:editor_icon).and_return("icon")
    allow(view).to receive(:params).and_return(controller: "names")

    # Stub the context menu partial to avoid requiring context helper
    allow(view).to receive(:render).and_call_original
    allow(view).to receive(:render).with(partial: 'layouts/context_menu').and_return('')

    # Stub CanCanCan authorization
    allow(view).to receive(:can?).with('loader/batch/review/mode', 'switch_on').and_return(false)
    allow(view).to receive(:can?).with('loader/batch/review/mode', 'switch_off').and_return(false)

    assign(:current_user, session_user)
    assign(:current_registered_user, registered_user)
  end

  context "when user is present" do
    it "displays the user dropdown menu" do
      render
      expect(rendered).to have_selector("a#user-dropdown-menu-link", text: session_user.full_name)
    end

    context "when user has groups" do
      before do
        allow(session_user).to receive(:groups).and_return(["edit", "admin"])
      end

      it "displays the user's groups" do
        render
        expect(rendered).to have_selector("a", text: "2 Security groups")
        expect(rendered).to have_selector("a", text: "1 Role")
        expect(rendered).to have_selector("a", text: "Edit")
        expect(rendered).to have_selector("a", text: "Admin")
        expect(rendered).to have_selector("a", text: "#{product.name} #{role.name}")
      end
    end

    context "when registered user is present" do
      context "when registered user has product roles" do
        it "displays the registered user's product roles" do
          render
          expect(rendered).to have_selector("a", text: "#{product.name} #{role.name}")
        end
      end
      context "when registered user does not have product roles" do
        let(:registered_user_1) { FactoryBot.create(:user, user_name: "Registered User 1") }
        let(:user_product_role) { FactoryBot.create(:user_product_role, product_role:, user: registered_user_1) }
        it "does not display the registered user's product roles" do
          render
          expect(rendered).not_to have_selector("a", text: role.name)
        end
      end
    end
  end

  context "when generic active directory user" do
    before do
      allow(view).to receive(:session).and_return({ generic_active_directory_user: true })
    end

    it "displays change password option as struck through" do
      render
      expect(rendered).to have_selector("span.strike-through", text: "Change Password")
    end
  end

  context "when not a generic active directory user" do
    before do
      allow(view).to receive(:session).and_return({ generic_active_directory_user: false })
    end

    it "displays change password link" do
      render
      expect(rendered).to have_selector("a", text: "Change password")
    end
  end

  it "displays sign out link" do
    render
    expect(rendered).to have_selector("a", text: "Sign out")
  end
end
