require 'rails_helper'

RSpec.describe ApplicationHelper, type: :helper do
  describe '#user_profile_tab_name' do
    context 'when session[:product_context_display_text] is present' do
      before do
        session[:product_context_display_text] = 'Test Context'
      end

      it 'returns the product context display text' do
        expect(helper.user_profile_tab_name).to eq('Test Context')
      end
    end

    context 'when session[:product_context_display_text] is not present' do
      before do
        session[:product_context_display_text] = nil
      end

      it 'returns nil' do
        expect(helper.user_profile_tab_name).to be_nil
      end
    end
  end
end
