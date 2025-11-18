# frozen_string_literal: true

require 'rails_helper'

RSpec.describe User::ProductRolesController, type: :controller do
  let(:session_user) { FactoryBot.create(:session_user, groups: ['login', 'admin']) }
  let(:current_user) { FactoryBot.create(:user) }
  let(:product) { FactoryBot.create(:product) }
  let(:role) { FactoryBot.create(:role) }
  let(:product_role) { FactoryBot.create(:product_role, product: product, role: role) }
  let(:user_product_role) { FactoryBot.create(:user_product_role, user: current_user, product_role: product_role) }

  before do
    emulate_user_login(session_user, current_user)
    allow(controller).to receive(:authorize!).and_return(true)
  end

  describe "POST #create" do
    let(:create_service) { instance_double(Users::ProductRoles::CreateService) }
    let(:user_product_role_params) do
      {
        user_product_role: {
          user_id: current_user.id,
          product_role_id: product_role.id
        }
      }
    end

    before do
      allow(Users::ProductRoles::CreateService).to receive(:call).and_return(create_service)
    end

    context "when service creates user product role successfully" do
      before do
        allow(create_service).to receive(:errors).and_return(ActiveModel::Errors.new(User::ProductRole.new))
        allow(create_service).to receive(:user_product_role).and_return(user_product_role)
      end

      subject { post :create, params: user_product_role_params, format: :turbo_stream }

      it "calls the CreateService with correct parameters" do
        subject
        expect(Users::ProductRoles::CreateService).to have_received(:call).with(
          user_id: current_user.id.to_s,
          product_role_id: product_role.id.to_s,
          username: session_user.username
        )
      end

      it "assigns the user product role" do
        subject
        expect(assigns(:upr)).to eq(user_product_role)
      end

      it "renders the 'create' template" do
        subject
        expect(response).to render_template("create")
      end

      it "returns success status" do
        subject
        expect(response).to have_http_status(:success)
      end
    end

    context "when service returns errors" do
      let(:errors) { ActiveModel::Errors.new(User::ProductRole.new) }

      before do
        errors.add(:base, "User with ID #{current_user.id} does not exist")
        allow(create_service).to receive(:errors).and_return(errors)
        allow(create_service).to receive(:user_product_role).and_return(nil)
      end

      subject { post :create, params: user_product_role_params, format: :turbo_stream }

      it "assigns the error message" do
        subject
        expect(assigns(:error)).to eq("User with ID #{current_user.id} does not exist")
      end

      it "renders the 'create_error' template" do
        subject
        expect(response).to render_template("create_error")
      end

      it "returns unprocessable_content status" do
        subject
        expect(response).to have_http_status(:unprocessable_content)
      end

      it "logs the error" do
        expect(Rails.logger).to receive(:error).with("User::ProductRolesController#create error: User with ID #{current_user.id} does not exist")
        subject
      end
    end

    context "when service returns multiple errors" do
      let(:errors) { ActiveModel::Errors.new(User::ProductRole.new) }

      before do
        errors.add(:base, "Error one")
        errors.add(:base, "Error two")
        allow(create_service).to receive(:errors).and_return(errors)
        allow(create_service).to receive(:user_product_role).and_return(nil)
      end

      subject { post :create, params: user_product_role_params, format: :turbo_stream }

      it "joins error messages with comma" do
        subject
        expect(assigns(:error)).to eq("Error one, Error two")
      end
    end
  end

  describe "DELETE #destroy" do
    let(:destroy_service) { instance_double(Users::ProductRoles::DestroyService) }
    let(:destroy_params) do
      {
        user_id: current_user.id,
        product_role_id: product_role.id
      }
    end

    before do
      allow(User::ProductRole).to receive(:find).with([current_user.id.to_s, product_role.id.to_s]).and_return(user_product_role)
      allow(Users::ProductRoles::DestroyService).to receive(:call).and_return(destroy_service)
    end

    context "when service destroys user product role successfully" do
      before do
        allow(destroy_service).to receive(:errors).and_return(ActiveModel::Errors.new(User::ProductRole.new))
      end

      subject { delete :destroy, params: destroy_params, format: :turbo_stream }

      it "finds the user product role" do
        subject
        expect(User::ProductRole).to have_received(:find).with([current_user.id.to_s, product_role.id.to_s])
      end

      it "calls the DestroyService with the user product role" do
        subject
        expect(Users::ProductRoles::DestroyService).to have_received(:call).with(user_product_role: user_product_role)
      end

      it "renders the 'destroy' template" do
        subject
        expect(response).to render_template("destroy")
      end

      it "returns success status" do
        subject
        expect(response).to have_http_status(:success)
      end
    end

    context "when service returns errors" do
      let(:errors) { ActiveModel::Errors.new(User::ProductRole.new) }

      before do
        errors.add(:base, "Cannot delete user product role")
        allow(destroy_service).to receive(:errors).and_return(errors)
      end

      subject { delete :destroy, params: destroy_params, format: :turbo_stream }

      it "assigns the error message" do
        subject
        expect(assigns(:error)).to eq("Cannot delete user product role")
      end

      it "renders the 'destroy_error' template" do
        subject
        expect(response).to render_template("destroy_error")
      end

      it "returns unprocessable_content status" do
        subject
        expect(response).to have_http_status(:unprocessable_content)
      end

      it "logs the error" do
        expect(Rails.logger).to receive(:error).with("User::ProductRolesController#destroy error: Cannot delete user product role")
        subject
      end
    end

    context "when service returns multiple errors" do
      let(:errors) { ActiveModel::Errors.new(User::ProductRole.new) }

      before do
        errors.add(:base, "Error one")
        errors.add(:base, "Error two")
        allow(destroy_service).to receive(:errors).and_return(errors)
      end

      subject { delete :destroy, params: destroy_params, format: :turbo_stream }

      it "joins error messages with comma" do
        subject
        expect(assigns(:error)).to eq("Error one, Error two")
      end
    end
  end
end
