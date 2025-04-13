require 'rails_helper'

RSpec.describe ProfileItemAnnotationsController, type: :controller do
  let(:session_user) { FactoryBot.create(:session_user, groups: ['login']) }
  let(:user) { FactoryBot.create(:user) }
  let!(:profile_item) { FactoryBot.create(:profile_item) }

  before do
    session[:username] = session_user.username
    session[:user_full_name] = session_user.full_name
    session[:groups] = session_user.groups

    allow(controller).to receive(:current_user).and_return(session_user)
    controller.instance_variable_set(:@current_user, session_user)
  end

  describe "POST #create" do
    let(:valid_params) do
      { profile_item_annotation: { profile_item_id: profile_item.id, value: "Test Annotation" } }
    end

    let(:invalid_params) do
      { profile_item_annotation: { profile_item_id: profile_item.id, value: "" } }
    end

    context "for authorized user" do
      before do
        allow(controller).to receive(:can?).with(:manage, instance_of(Profile::ProfileItemAnnotation)).and_return(true)
      end

      it "creates a new profile_item_annotation and renders :create" do
        expect {
          post :create, params: valid_params, format: :turbo_stream
        }.to change(Profile::ProfileItemAnnotation, :count).by(1)

        expect(assigns(:message)).to eq("Saved")
        expect(response).to render_template(:create)
        expect(response.media_type).to eq("text/vnd.turbo-stream.html")
      end

      it "fails to create a profile_item_annotation with invalid params and renders :create_failed" do
        expect {
          post :create, params: invalid_params, format: :turbo_stream
        }.not_to change(Profile::ProfileItemAnnotation, :count)

        expect(assigns(:message)).to include("Validation failed")
        expect(response).to render_template("create_failed")
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context "for non-authorized user" do
      before do
        allow(controller).to receive(:can?).with(:manage, instance_of(Profile::ProfileItemAnnotation)).and_return(false)
      end

      it "returns an error" do
        post :create, params: valid_params, format: :turbo_stream
        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end

  describe "PUT #update" do
    let!(:profile_item_annotation) { FactoryBot.create(:profile_item_annotation, profile_item: profile_item, value: "Initial Value") }

    before do
      allow(controller).to receive(:can?).with(:manage, profile_item_annotation).and_return(true)
    end

    context "for non-authorized user" do
      before do
        allow(controller).to receive(:can?).with(:manage, profile_item_annotation).and_return(false)
      end

      it "is forbidden access" do
        put :update, params: { id: profile_item_annotation.id, profile_item_annotation: { value: "Updated Value" } }, format: :turbo_stream
        expect(response).to have_http_status(:forbidden)
      end
    end

    context "when value is blank" do
      it "destroys the profile_item_annotation and renders :delete" do
        put :update, params: { id: profile_item_annotation.id, profile_item_annotation: { value: "" } }, format: :turbo_stream

        expect(assigns(:message)).to eq("Deleted")
        expect { profile_item_annotation.reload }.to raise_error(ActiveRecord::RecordNotFound)
        expect(response).to render_template(:delete)
      end
    end

    context "when value is not blank" do
      it "updates the profile_item_annotation and renders :update" do
        put :update, params: { id: profile_item_annotation.id, profile_item_annotation: { value: "Updated Value" } }, format: :turbo_stream

        expect(assigns(:message)).to eq("Updated")
        expect(profile_item_annotation.reload.value).to eq("Updated Value")
        expect(response).to render_template(:update)
      end
    end

    context "when value is unchanged" do
      it "does not update the profile_item_annotation and renders :update" do
        put :update, params: { id: profile_item_annotation.id, profile_item_annotation: { value: "Initial Value" } }, format: :turbo_stream

        expect(assigns(:message)).to eq("No change")
        expect(profile_item_annotation.reload.value).to eq("Initial Value")
        expect(response).to render_template(:update)
      end
    end

    context "when an error occurs during update" do
      before do
        allow_any_instance_of(Profile::ProfileItemAnnotation).to receive(:update).and_raise(StandardError, "Update failed")
      end

      it "renders :update_failed with an error message" do
        put :update, params: { id: profile_item_annotation.id, profile_item_annotation: { value: "Updated Value" } }, format: :turbo_stream

        expect(assigns(:message)).to eq("Update failed")
        expect(response).to render_template(:update_failed)
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

end
