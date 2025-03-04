require 'rails_helper'

RSpec.describe "layouts/_menu_links.html.erb", type: :view do
  let(:user) { FactoryBot.create(:session_user) }
  let(:registered_user) { FactoryBot.create(:user, user_name: "Registered User") }
  let(:role_type) { FactoryBot.create(:role_type) }
  let(:product) { FactoryBot.create(:product, name: "Product") }
  let!(:user_product_role) { FactoryBot.create(:user_product_role, product: product, role_type: role_type, user: registered_user) }

  before do
    allow(view).to receive(:can?).and_return(true)
    allow(view).to receive(:params).and_return(controller: "any_controller")
  end

  context 'when product context display text is present' do
    before do
      session[:product_context_display_text] = "Test Context"
    end

    context 'when product context is not default' do
      before do
        session[:product_context_is_default] = false
        render
      end

      it 'displays the product context display text' do
        expect(rendered).to have_content("In Test Context")
      end

      it 'displays the clear link' do
        expect(rendered).to have_link("( clear )", href: clear_product_contexts_path)
      end
    end

    context 'when product context is default' do
      before do
        session[:product_context_is_default] = true
        render
      end

      it 'displays the product context display text' do
        expect(rendered).to have_content("In Test Context")
      end

      it 'does not display the clear link' do
        expect(rendered).not_to have_link("( clear )", href: clear_product_contexts_path)
      end
    end
  end

  context 'when product context display text is not present' do
    before do
      session[:product_context_display_text] = nil
      render
    end

    it 'does not display the product context display text' do
      expect(rendered).not_to have_content("In Test Context")
    end

    it 'does not display the clear link' do
      expect(rendered).not_to have_link("( clear )", href: clear_product_contexts_path)
    end
  end
end
