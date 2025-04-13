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

  before do
    allow(controller).to receive(:current_registered_user).and_return(user)
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
    end
  end

  describe 'rescue_from CanCan::AccessDenied' do
    before do
      allow(SessionUser).to receive(:new).and_return(session_user)
      allow(session_user).to receive(:registered_user).and_return(user)

      session[:username] = session_user.username
      session[:user_full_name] = session_user.full_name
      session[:groups] = session_user.groups
    end

    context 'when format is turbo_stream' do
      it 'renders the flash_message partial with status forbidden' do
        request.headers['Accept'] = 'text/vnd.turbo-stream.html'
        get :index, format: :turbo_stream

        expect(response).to have_http_status(:forbidden)
        expect(response.body).to include('common-error-message-container')
      end
    end

    context 'when format is js' do
      it 'renders the flash_message partial with status forbidden' do
        get :index, format: :js

        expect(response).to have_http_status(:forbidden)
        expect(response).to render_template('layouts/shared/message')
      end
    end

    context 'when format is html' do
      it 'redirects to the referrer or root path' do
        request.env['HTTP_REFERER'] = root_path
        get :index

        expect(response).to have_http_status(:forbidden)
      end
    end
  end
end
