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
    let(:product) { FactoryBot.create(:product) }
    let(:product_context_service) { instance_double(Products::ProductContextService) }

    before do
      allow(SessionUser).to receive(:new).and_return(session_user)
      allow(session_user).to receive(:registered_user).and_return(user)
      allow(controller).to receive(:product_context_service).and_return(product_context_service)
    end

    context 'when session variables are set' do
      before do
        session[:username] = session_user.username
        session[:user_full_name] = session_user.full_name
        session[:groups] = session_user.groups
      end

      it 'sets the current_user and current_registered_user' do
        allow(controller).to receive(:current_product_from_context).and_return(nil)
        allow(controller).to receive(:set_default_product_context_if_missing)

        controller.send(:continue_user_session)

        expect(controller.instance_variable_get(:@current_user)).to eq(session_user)
        expect(controller.instance_variable_get(:@current_registered_user)).to eq(user)
      end

      it 'calls set_default_product_context_if_missing' do
        allow(controller).to receive(:current_product_from_context).and_return(nil)
        expect(controller).to receive(:set_default_product_context_if_missing)

        controller.send(:continue_user_session)
      end

      context 'when current_product_from_context is present' do
        before do
          session[:current_context_id] = 1
          allow(product_context_service).to receive(:product_with_context).with(1).and_return(product)
          allow(controller).to receive(:set_default_product_context_if_missing)
        end

        it 'calls set_current_product_from_context on current_user' do
          expect(session_user).to receive(:set_current_product_from_context).with(product)

          controller.send(:continue_user_session)
        end
      end

      context 'when current_product_from_context is nil' do
        before do
          session[:current_context_id] = nil
          allow(controller).to receive(:set_default_product_context_if_missing)
        end

        it 'does not call set_current_product_from_context' do
          expect(session_user).not_to receive(:set_current_product_from_context)

          controller.send(:continue_user_session)
        end
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

  describe "#product_tab_service" do
    let(:products) { [instance_double('Product')] }
    let(:product_tab_service_instance) { instance_double('Products::ProductTabService') }

    before do
      allow(user).to receive(:available_products_from_roles).and_return(products)
    end

    context 'when current_context_id is present' do
      before do
        session[:current_context_id] = 42
      end

      it 'calls ProductTabService.for_context with the context_id' do
        expect(Products::ProductTabService).to receive(:for_context)
          .with(42)
          .and_return(product_tab_service_instance)

        result = controller.send(:product_tab_service)
        expect(result).to eq(product_tab_service_instance)
      end

      it 'memoizes the service instance' do
        allow(Products::ProductTabService).to receive(:for_context)
          .with(42)
          .and_return(product_tab_service_instance)

        first_result = controller.send(:product_tab_service)

        expect(Products::ProductTabService).not_to receive(:for_context)
        second_result = controller.send(:product_tab_service)

        expect(first_result).to eq(second_result)
        expect(first_result).to eq(product_tab_service_instance)
      end
    end

    context 'when current_context_id is nil' do
      before do
        session[:current_context_id] = nil
        allow(user).to receive(:default_product_context_id).and_return(nil)
      end

      it 'creates a new ProductTabService instance with products' do
        expect(Products::ProductTabService).to receive(:call)
          .with(products)
          .and_return(product_tab_service_instance)

        result = controller.send(:product_tab_service)
        expect(result).to eq(product_tab_service_instance)
      end

      it 'memoizes the service instance' do
        allow(Products::ProductTabService).to receive(:call)
          .with(products)
          .and_return(product_tab_service_instance)

        first_result = controller.send(:product_tab_service)

        expect(Products::ProductTabService).not_to receive(:call)
        second_result = controller.send(:product_tab_service)

        expect(first_result).to eq(second_result)
        expect(first_result).to eq(product_tab_service_instance)
      end
    end

    context 'when current_registered_user has no products' do
      let(:products) { [] }

      before do
        session[:current_context_id] = nil
        allow(user).to receive(:default_product_context_id).and_return(nil)
      end

      it 'passes empty array to ProductTabService' do
        expect(Products::ProductTabService).to receive(:call)
          .with([])
          .and_return(product_tab_service_instance)

        controller.send(:product_tab_service)
      end
    end

    context 'when current_registered_user has multiple products' do
      let(:product1) { instance_double('Product') }
      let(:product2) { instance_double('Product') }
      let(:products) { [product1, product2] }

      before do
        session[:current_context_id] = nil
        allow(user).to receive(:default_product_context_id).and_return(nil)
      end

      it 'passes all products to ProductTabService' do
        expect(Products::ProductTabService).to receive(:call)
          .with([product1, product2])
          .and_return(product_tab_service_instance)

        controller.send(:product_tab_service)
      end
    end
  end

  describe "#current_context_id" do
    context "when session has current_context_id" do
      it "returns the current context ID from the session" do
        session[:current_context_id] = 42
        expect(controller.send(:current_context_id)).to eq(42)
      end

      it "prioritizes session value over user default" do
        session[:current_context_id] = 42
        allow(user).to receive(:default_product_context_id).and_return(99)
        expect(controller.send(:current_context_id)).to eq(42)
      end
    end

    context "when session current_context_id is nil" do
      it "returns the user's default_product_context_id" do
        session[:current_context_id] = nil
        allow(user).to receive(:default_product_context_id).and_return(99)
        expect(controller.send(:current_context_id)).to eq(99)
      end

      it "returns nil when user has no default_product_context_id" do
        session[:current_context_id] = nil
        allow(user).to receive(:default_product_context_id).and_return(nil)
        expect(controller.send(:current_context_id)).to be_nil
      end
    end
  end

  describe "#current_context_name" do
    context "when session has current_context_name" do
      it "returns the current context name from the session" do
        session[:current_context_id] = 1
        session[:current_context_name] = "Test Context"
        expect(controller.send(:current_context_name)).to eq("Test Context")
      end
    end

    context "when session context_name is nil but product from context exists" do
      let(:product) { instance_double('Product', name: 'APNI Context') }

      before do
        session[:current_context_id] = 1
        session[:current_context_name] = nil
        allow(controller).to receive(:current_product_from_context).and_return(product)
      end

      it "returns the product name from context" do
        expect(controller.send(:current_context_name)).to eq("APNI Context")
      end
    end

    context "when product from context exists but name is nil" do
      let(:product) { instance_double('Product', name: nil) }

      before do
        session[:current_context_id] = 1
        session[:current_context_name] = nil
        allow(controller).to receive(:current_product_from_context).and_return(product)
      end

      it "falls back to 'No Context Selected'" do
        expect(controller.send(:current_context_name)).to eq("No Context Selected")
      end
    end

    context "when current_product_from_context is nil" do
      before do
        session[:current_context_id] = 1
        session[:current_context_name] = nil
        allow(controller).to receive(:current_product_from_context).and_return(nil)
      end

      it "returns 'No Context Selected'" do
        expect(controller.send(:current_context_name)).to eq("No Context Selected")
      end
    end

    context "when current_context_id is nil" do
      it "returns 'Select Context'" do
        session[:current_context_id] = nil
        expect(controller.send(:current_context_name)).to eq("Select Context")
      end
    end
  end

  describe "#product_context_service" do
    it "returns a ProductContextService instance" do
      expect(controller.send(:product_context_service)).to be_a(Products::ProductContextService)
    end
  end

  describe "#current_product_from_context" do
    let(:product) { FactoryBot.create(:product) }
    let(:product_context_service) { instance_double(Products::ProductContextService) }

    before do
      allow(controller).to receive(:product_context_service).and_return(product_context_service)
    end

    context "when current_context_id is nil" do
      it "returns nil" do
        session[:current_context_id] = nil
        expect(controller.send(:current_product_from_context)).to be_nil
      end
    end

    context "when current_context_id is present" do
      it "calls product_context_service.product_with_context" do
        session[:current_context_id] = 1
        expect(product_context_service).to receive(:product_with_context).with(1).and_return(product)

        result = controller.send(:current_product_from_context)
        expect(result).to eq(product)
      end
    end
  end

  describe "#set_default_product_context_if_missing" do
    before do
      allow(Rails.configuration).to receive(:multi_product_tabs_enabled).and_return(true)
    end

    context "when user already has a default_product_context_id" do
      before do
        allow(user).to receive(:default_product_context_id).and_return(42)
      end

      it "returns early without making changes" do
        expect(user).not_to receive(:default_product_context_id=)
        expect(user).not_to receive(:save)

        controller.send(:set_default_product_context_if_missing)

        expect(session[:current_context_id]).to be_nil
        expect(session[:current_context_name]).to be_nil
      end
    end

    context "when user has no default context" do
      before do
        allow(user).to receive(:default_product_context_id).and_return(nil)
      end

      context "and has available products" do
        let(:product1) { instance_double('Product', context_id: 100, name: 'APNI') }
        let(:products) { [product1] }

        before do
          allow(user).to receive(:available_products_from_roles).and_return(products)
          allow(user).to receive(:default_product_context_id=)
          allow(user).to receive(:save).and_return(true)
        end

        it "sets user's default_product_context_id to first product's context_id" do
          expect(user).to receive(:default_product_context_id=).with(100)

          controller.send(:set_default_product_context_if_missing)
        end

        it "saves the user" do
          expect(user).to receive(:save)

          controller.send(:set_default_product_context_if_missing)
        end

        it "sets session[:current_context_id] to product's context_id" do
          controller.send(:set_default_product_context_if_missing)

          expect(session[:current_context_id]).to eq(100)
        end

        it "sets session[:current_context_name] to product's name" do
          controller.send(:set_default_product_context_if_missing)

          expect(session[:current_context_name]).to eq('APNI')
        end
      end

      context "and save fails" do
        let(:product1) { instance_double('Product', context_id: 100, name: 'APNI') }
        let(:products) { [product1] }
        let(:errors) { instance_double('ActiveModel::Errors') }

        before do
          allow(user).to receive(:available_products_from_roles).and_return(products)
          allow(user).to receive(:default_product_context_id=)
          allow(user).to receive(:save).and_return(false)
          allow(user).to receive(:user_name).and_return('test_user')
          allow(user).to receive(:errors).and_return(errors)
          allow(errors).to receive(:full_messages).and_return(['Validation failed'])
        end

        it "logs error messages with username and validation errors" do
          expect(Rails.logger).to receive(:error).with("Could not save default product context for user test_user")
          expect(Rails.logger).to receive(:error).with("Error: Validation failed")

          controller.send(:set_default_product_context_if_missing)
        end

        it "does not set session[:current_context_id]" do
          allow(Rails.logger).to receive(:error)

          controller.send(:set_default_product_context_if_missing)

          expect(session[:current_context_id]).to be_nil
        end

        it "does not set session[:current_context_name]" do
          allow(Rails.logger).to receive(:error)

          controller.send(:set_default_product_context_if_missing)

          expect(session[:current_context_name]).to be_nil
        end

        it "attempts to set user's default_product_context_id before saving" do
          allow(Rails.logger).to receive(:error)
          expect(user).to receive(:default_product_context_id=).with(100)

          controller.send(:set_default_product_context_if_missing)
        end

        it "attempts to save the user" do
          allow(Rails.logger).to receive(:error)
          expect(user).to receive(:save).and_return(false)

          controller.send(:set_default_product_context_if_missing)
        end
      end

      context "and has multiple available products" do
        let(:product1) { instance_double('Product', context_id: 100, name: 'APNI') }
        let(:product2) { instance_double('Product', context_id: 200, name: 'APC') }
        let(:products) { [product1, product2] }

        before do
          allow(user).to receive(:available_products_from_roles).and_return(products)
          allow(user).to receive(:default_product_context_id=)
          allow(user).to receive(:save).and_return(true)
        end

        it "uses the first product" do
          expect(user).to receive(:default_product_context_id=).with(100)

          controller.send(:set_default_product_context_if_missing)

          expect(session[:current_context_id]).to eq(100)
          expect(session[:current_context_name]).to eq('APNI')
        end
      end

      context "and has no available products (empty array)" do
        before do
          allow(user).to receive(:available_products_from_roles).and_return([])
        end

        it "returns early without making changes" do
          expect(user).not_to receive(:default_product_context_id=)
          expect(user).not_to receive(:save)

          controller.send(:set_default_product_context_if_missing)

          expect(session[:current_context_id]).to be_nil
          expect(session[:current_context_name]).to be_nil
        end
      end

      context "and available_products_from_roles returns nil" do
        before do
          allow(user).to receive(:available_products_from_roles).and_return(nil)
        end

        it "returns early without making changes" do
          expect(user).not_to receive(:default_product_context_id=)
          expect(user).not_to receive(:save)

          controller.send(:set_default_product_context_if_missing)

          expect(session[:current_context_id]).to be_nil
          expect(session[:current_context_name]).to be_nil
        end
      end
    end

    context "when multi_product_tabs_enabled is false" do
      before do
        allow(Rails.configuration).to receive(:multi_product_tabs_enabled).and_return(false)
      end

      it "returns early without making changes" do
        expect(user).not_to receive(:default_product_context_id=)
        expect(user).not_to receive(:save)

        controller.send(:set_default_product_context_if_missing)

        expect(session[:current_context_id]).to be_nil
        expect(session[:current_context_name]).to be_nil
      end
    end
  end
end
