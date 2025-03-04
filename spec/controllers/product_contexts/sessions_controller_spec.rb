# frozen_string_literal: true

#   Copyright 2015 Australian National Botanic Gardens
#
#   This file is part of the NSL Editor.
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.

require 'rails_helper'

RSpec.describe ProductContexts::SessionsController, type: :controller do

  let!(:session_user) { FactoryBot.create(:session_user, groups: ["login", "edit"]) }
  let!(:user) { FactoryBot.create(:user) }
  let(:non_default_product_context) { FactoryBot.create(:user_product_context, is_default: false, user: user) }
  let(:default_product_context) { FactoryBot.create(:user_product_context, user: user, is_default: true) }

  before do
    session[:username] = session_user.username
    session[:user_full_name] = session_user.full_name
    session[:groups] = session_user.groups

    allow(controller).to receive(:current_registered_user).and_return(user)
    allow(controller).to receive_message_chain(:current_registered_user, :default_product_context).and_return(default_product_context)
    allow(controller).to receive(:can?).and_return(true)
  end

  describe 'POST #switch' do
    context 'when the product context exists' do
      it 'sets the product context session and redirects' do
        post :switch, params: { context_id: non_default_product_context.context_id }

        expect(session[:product_context_is_default]).to eq(non_default_product_context.is_default?)
        expect(session[:product_context_display_text]).to eq(non_default_product_context.products.map(&:name).join("/"))
        expect(response.status).to eq(302)
      end
    end

    context 'when the product context does not exist' do
      it 'sets to the default context' do
        post :switch, params: { context_id: 'nonexistent' }

        expect(session[:product_context_is_default]).to eq(default_product_context.is_default?)
        expect(session[:product_context_display_text]).to eq(default_product_context.products.map(&:name).join("/"))
        expect(response.status).to eq(302)
      end
    end
  end

  describe 'POST #clear' do
    it 'sets the default product context session and redirects' do
      post :clear

      expect(session[:product_context_is_default]).to eq(default_product_context.is_default?)
      expect(session[:product_context_display_text]).to eq(default_product_context.products.map(&:name).join("/"))
      expect(response.status).to eq(302)
    end
  end
end
