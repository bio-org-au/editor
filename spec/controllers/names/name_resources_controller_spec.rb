# frozen_string_literal: true

require "rails_helper"

RSpec.describe Names::NameResourcesController, type: :controller do
  let(:session_user) { FactoryBot.create(:session_user, groups: ["login", "edit"]) }
  let(:current_user) { FactoryBot.create(:user) }
  let(:name) { FactoryBot.create(:name) }
  let(:resource_host) { FactoryBot.create(:resource_host) }

  before do
    emulate_user_login(session_user, current_user)
    allow(controller).to receive(:can?).with(:manage, :all).and_return(true)
    allow(controller).to receive(:authorize!).and_return(true)
  end

  describe "POST #create" do
    let(:valid_params) do
      {
        name_id: name.id,
        name_resource: {
          resource_host_id: resource_host.id,
          value: "test-resource-id",
          note: "Test note"
        }
      }
    end

    let(:invalid_params) do
      {
        name_id: name.id,
        name_resource: {
          resource_host_id: nil
        }
      }
    end

    context "with valid parameters" do
      subject { post :create, params: valid_params, format: :turbo_stream }

      it "creates a new name_resource" do
        expect { subject }.to change(NameResource, :count).by(1)
      end

      it "assigns @name" do
        subject
        expect(assigns(:name)).to eq(name)
      end

      it "assigns @name_resource" do
        subject
        expect(assigns(:name_resource)).to be_a(NameResource)
        expect(assigns(:name_resource)).to be_persisted
      end

      it "sets current_user on the name_resource" do
        subject
        expect(assigns(:name_resource).created_by).to eq(session_user.username)
        expect(assigns(:name_resource).updated_by).to eq(session_user.username)
      end

      it "assigns success message" do
        subject
        expect(assigns(:message)).to eq("Saved")
      end

      it "renders the create template" do
        subject
        expect(response).to render_template(:create)
      end

      it "responds with turbo_stream format" do
        subject
        expect(response.media_type).to eq("text/vnd.turbo-stream.html")
      end

      it "returns successful status" do
        subject
        expect(response).to have_http_status(:success)
      end
    end

    context "with invalid parameters" do
      subject { post :create, params: invalid_params, format: :turbo_stream }

      before do
        allow_any_instance_of(NameResource).to receive(:save).and_return(false)
        allow_any_instance_of(NameResource).to receive(:errors).and_return(
          double(full_messages: ["Resource host must exist"])
        )
      end

      it "does not create a new name_resource" do
        expect { subject }.not_to change(NameResource, :count)
      end

      it "assigns @name_resource" do
        subject
        expect(assigns(:name_resource)).to be_a(NameResource)
        expect(assigns(:name_resource)).not_to be_persisted
      end

      it "assigns error message" do
        subject
        expect(assigns(:message)).to eq("Resource host must exist")
      end

      it "logs the error" do
        allow(Rails.logger).to receive(:error).with("Failed to create NameResource: Resource host must exist")
        subject
        expect(Rails.logger).to have_received(:error).with("Failed to create NameResource: Resource host must exist")
      end

      it "renders the create_failed template" do
        subject
        expect(response).to render_template("create_failed")
      end

      it "returns unprocessable_content status" do
        subject
        expect(response).to have_http_status(:unprocessable_content)
      end
    end

    context "when name is not found" do
      let(:invalid_name_params) do
        {
          name_id: -1,
          name_resource: {
            resource_host_id: resource_host.id,
            value: "test-resource-id"
          }
        }
      end

      it "raises ActiveRecord::RecordNotFound" do
        expect {
          post :create, params: invalid_name_params, format: :turbo_stream
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  describe "PATCH #update" do
    let!(:name_resource) do
      FactoryBot.create(:name_resource, name: name, resource_host: resource_host)
    end

    let(:update_params) do
      {
        name_id: name.id,
        id: name_resource.id,
        name_resource: {
          value: "updated-resource-id",
          note: "Updated note"
        }
      }
    end

    subject { patch :update, params: update_params, format: :turbo_stream }

    context "with valid parameters" do
      it "assigns @name" do
        subject
        expect(assigns(:name)).to eq(name)
      end

      it "assigns @name_resource" do
        subject
        expect(assigns(:name_resource)).to eq(name_resource)
      end

      it "sets current_user on the name_resource" do
        subject
        name_resource.reload
        expect(name_resource.updated_by).to eq(session_user.username)
      end

      it "updates the name_resource attributes" do
        subject
        name_resource.reload
        expect(name_resource.value).to eq("updated-resource-id")
        expect(name_resource.note).to eq("Updated note")
      end

      it "assigns success message" do
        subject
        expect(assigns(:message)).to eq("Updated")
      end

      it "renders the update template" do
        subject
        expect(response).to render_template(:update)
      end

      it "responds with turbo_stream format" do
        subject
        expect(response.media_type).to eq("text/vnd.turbo-stream.html")
      end

      it "returns successful status" do
        subject
        expect(response).to have_http_status(:success)
      end
    end

    context "when no changes are made" do
      let!(:name_resource) do
        FactoryBot.create(:name_resource, name: name, value: "updated-resource-id", note: "testing", resource_host: resource_host)
      end

      let(:update_params) do
        {
          name_id: name.id,
          id: name_resource.id,
          name_resource: {
            value: "updated-resource-id",
            note: "testing"
          }
        }
      end

      it "assigns 'No change' message" do
        subject
        expect(assigns(:message)).to eq("No change")
      end

      it "renders the update template" do
        subject
        expect(response).to render_template(:update)
      end

      it "returns successful status" do
        subject
        expect(response).to have_http_status(:success)
      end

      it "does not modify the database" do
        initial_updated_at = name_resource.updated_at
        subject
        name_resource.reload
        expect(name_resource.updated_at.to_i).to eq(initial_updated_at.to_i)
      end
    end

    context "with invalid parameters" do
      subject { patch :update, params: update_params, format: :turbo_stream }

      before do
        allow_any_instance_of(NameResource).to receive(:save).and_return(false)
        allow_any_instance_of(NameResource).to receive(:errors).and_return(
          double(full_messages: ["Validation failed"])
        )
      end

      it "assigns @name_resource" do
        subject
        expect(assigns(:name_resource)).to eq(name_resource)
      end

      it "assigns error message" do
        subject
        expect(assigns(:message)).to eq("Validation failed")
      end

      it "logs the error" do
        allow(Rails.logger).to receive(:error).with("Failed to update NameResource: Validation failed")
        subject
        expect(Rails.logger).to have_received(:error).with("Failed to update NameResource: Validation failed")
      end

      it "renders the update_failed template" do
        subject
        expect(response).to render_template("update_failed")
      end

      it "returns unprocessable_content status" do
        subject
        expect(response).to have_http_status(:unprocessable_content)
      end
    end

    context "when name_resource is not found" do
      let(:invalid_id_params) do
        {
          name_id: name.id,
          id: -1,
          name_resource: {
            value: "updated-resource-id"
          }
        }
      end

      it "raises ActiveRecord::RecordNotFound" do
        expect {
          patch :update, params: invalid_id_params, format: :turbo_stream
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context "when name is not found" do
      let(:invalid_name_params) do
        {
          name_id: -1,
          id: name_resource.id,
          name_resource: {
            value: "updated-resource-id"
          }
        }
      end

      it "raises ActiveRecord::RecordNotFound" do
        expect {
          patch :update, params: invalid_name_params, format: :turbo_stream
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  describe "DELETE #destroy" do
    let!(:name_resource) do
      FactoryBot.create(:name_resource, name: name, resource_host: resource_host)
    end

    let(:destroy_params) do
      {
        name_id: name.id,
        id: name_resource.id
      }
    end

    context "when successful" do
      subject { delete :destroy, params: destroy_params, format: :turbo_stream }

      it "assigns @name" do
        subject
        expect(assigns(:name)).to eq(name)
      end

      it "assigns @name_resource" do
        subject
        expect(assigns(:name_resource)).to eq(name_resource)
      end

      it "destroys the name_resource" do
        expect { subject }.to change(NameResource, :count).by(-1)
      end

      it "assigns success message" do
        subject
        expect(assigns(:message)).to eq("Deleted")
      end

      it "renders the destroy template" do
        subject
        expect(response).to render_template(:destroy)
      end

      it "responds with turbo_stream format" do
        subject
        expect(response.media_type).to eq("text/vnd.turbo-stream.html")
      end

      it "returns successful status" do
        subject
        expect(response).to have_http_status(:success)
      end
    end

    context "when destroy fails" do
      subject { delete :destroy, params: destroy_params, format: :turbo_stream }

      before do
        allow_any_instance_of(NameResource).to receive(:destroy).and_return(false)
        allow_any_instance_of(NameResource).to receive(:errors).and_return(
          double(full_messages: ["Cannot delete resource"])
        )
      end

      it "does not destroy the name_resource" do
        expect { subject }.not_to change(NameResource, :count)
      end

      it "assigns error message" do
        subject
        expect(assigns(:message)).to eq("Cannot delete resource")
      end

      it "logs the error" do
        allow(Rails.logger).to receive(:error).with("Failed to delete NameResource: Cannot delete resource")
        subject
        expect(Rails.logger).to have_received(:error).with("Failed to delete NameResource: Cannot delete resource")
      end

      it "renders the destroy_failed template" do
        subject
        expect(response).to render_template("destroy_failed")
      end

      it "returns unprocessable_content status" do
        subject
        expect(response).to have_http_status(:unprocessable_content)
      end
    end

    context "when name_resource is not found" do
      let(:invalid_id_params) do
        {
          name_id: name.id,
          id: -1
        }
      end

      it "raises ActiveRecord::RecordNotFound" do
        expect {
          delete :destroy, params: invalid_id_params, format: :turbo_stream
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context "when name is not found" do
      let(:invalid_name_params) do
        {
          name_id: -1,
          id: name_resource.id
        }
      end

      it "raises ActiveRecord::RecordNotFound" do
        expect {
          delete :destroy, params: invalid_name_params, format: :turbo_stream
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  describe "before_action :find_name" do
    context "with valid name_id" do
      it "loads the name" do
        post :create, params: {name_id: name.id, name_resource: {resource_host_id: resource_host.id, value: "test"}}, format: :turbo_stream
        expect(assigns(:name)).to eq(name)
      end
    end

    context "with invalid name_id" do
      it "raises ActiveRecord::RecordNotFound" do
        expect {
          post :create, params: {name_id: -1, name_resource: {resource_host_id: resource_host.id, value: "test"}}, format: :turbo_stream
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
end
