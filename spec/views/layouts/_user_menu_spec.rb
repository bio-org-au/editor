require "rails_helper"

RSpec.describe "layouts/_user_menu.html.erb", type: :view do
  let(:session_user) { FactoryBot.create(:session_user) }
  let(:registered_user) { FactoryBot.create(:user, user_name: "Registered User") }
  let(:role_type) { FactoryBot.create(:role_type) }
  let(:product) { FactoryBot.create(:product, name: "Product") }
  let!(:user_product_role) { FactoryBot.create(:user_product_role, product: product, role_type: role_type, user: registered_user) }

  before do
    allow(view).to receive(:editor_icon).and_return("icon")
    allow(view).to receive(:params).and_return(controller: "names")

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
        expect(rendered).to have_selector("a", text: "1 Role type")
        expect(rendered).to have_selector("a", text: "Edit")
        expect(rendered).to have_selector("a", text: "Admin")
        expect(rendered).to have_selector("a", text: "#{product.name} #{user_product_role.role_type.name}")
      end
    end

    context "when registered user is present" do
      context "when registered user has product roles" do
        it "displays the registered user's product roles" do
          render
          expect(rendered).to have_selector("a", text: "#{product.name} #{role_type.name}")
        end
      end
      context "when registered user does not have product roles" do
        let(:registered_user_1) { FactoryBot.create(:user, user_name: "Registered User 1") }
        let!(:user_product_role) { FactoryBot.create(:user_product_role, product: product, role_type: role_type, user: registered_user_1) }
        it "does not display the registered user's product roles" do
          render
          expect(rendered).not_to have_selector("a", text: role_type.name)
        end
      end
    end

    context "when user has product contexts" do
      let!(:product_context) { FactoryBot.create(:product_context) }
      let!(:user_product_context) { FactoryBot.create(:user_product_context, user: registered_user, is_default: true, context_id: product_context.context_id) }

      let!(:product_context2) { FactoryBot.create(:product_context) }
      let!(:user_product_context2) { FactoryBot.create(:user_product_context, user: registered_user, is_default: false, context_id: product_context2.context_id) }

      before do
        allow(session_user).to receive(:groups).and_return(["login"])
      end

      it "displays the user's product contexts" do
        render
        expect(rendered).to have_selector("a", text: "Switch to #{user_product_context.products.map(&:name).join('/')} context")
        expect(rendered).to have_selector("a", text: "Switch to #{user_product_context2.products.map(&:name).join('/')} context")
      end
    end

    context "when user has no product context" do
      before do
        allow(session_user).to receive(:groups).and_return(["login"])
      end

      it "does not display a product context" do
        render
        expect(rendered).not_to have_selector("a", text: "Switch to")
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
