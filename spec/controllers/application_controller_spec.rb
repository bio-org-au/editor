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

RSpec.describe ApplicationController, type: :controller do
  controller do
    def index
      render plain: "Hello World"
    end
  end

  let!(:user) { FactoryBot.create(:user) }
  let!(:session_user) { FactoryBot.create(:session_user, username: user.user_name, full_name: "Test User", groups: ['login','edit']) }
  let(:product_context) { FactoryBot.create(:product_context) }
  let(:user_product_context) { FactoryBot.create(:user_product_context, user: user, is_default: true, context_id: product_context.context_id) }

  before do
    allow(controller).to receive(:current_registered_user).and_return(user)
    allow(user).to receive(:default_product_context).and_return(user_product_context)
  end

  describe "#continue_user_session" do
    before do
      allow(SessionUser).to receive(:new).and_return(session_user)
      allow(session_user).to receive(:registered_user).and_return(user)
    end

    context 'when session variables are set' do
      before do
        session[:username] = session_user.username
        session[:user_full_name] = session_user.full_name
        session[:groups] = session_user.groups
      end

      it 'sets the current_user and current_registered_user' do
        controller.send(:continue_user_session)

        expect(controller.instance_variable_get(:@current_user)).to eq(session_user)
        expect(controller.instance_variable_get(:@current_registered_user)).to eq(user)
      end

      it 'sets the product context session' do
        controller.send(:continue_user_session)

        expect(session[:product_context_is_default]).to eq(user_product_context.is_default?)
        expect(session[:product_context_display_text]).to eq(user_product_context.products.map(&:name).join("/"))
      end
    end

  end

  describe "#set_product_context_session" do
    context 'when session variables are not set' do
      it 'sets the session variables based on the default product context' do
        controller.send(:set_product_context_session)

        expect(session[:product_context_is_default]).to eq(user_product_context.is_default)
        expect(session[:product_context_display_text]).to eq(user_product_context.products.map(&:name).join("/"))
      end
    end

    context 'when session variables are already set' do
      before do
        session[:product_context_is_default] = false
        session[:product_context_display_text] = "Existing Context"
      end

      it 'does not overwrite the existing session variables' do
        controller.send(:set_product_context_session)

        expect(session[:product_context_is_default]).to eq(false)
        expect(session[:product_context_display_text]).to eq("Existing Context")
      end
    end
  end
end
