# frozen_string_literal: true

require "rails_helper"

RSpec.describe ProfileItemReferencesController, type: :controller do
  let(:session_user) { FactoryBot.create(:session_user, groups: ["login"]) }
  let(:profile_item) { instance_double("Profile::ProfileItem", id: 1, product_item_config: double(id: 10)) }
  let(:profile_item_reference) do
    instance_double(
      "Profile::ProfileItemReference",
      profile_item_id: 1,
      reference_id: 99,
      annotation: "Existing annotation",
      profile_item_id_reference_id: "1_99",
      profile_item: profile_item
    )
  end

  before do
    emulate_user_login(session_user)
    allow(Profile::ProfileItemReference).to receive(:find_by).and_return(profile_item_reference)
    allow(controller).to receive(:can?).with(:manage, profile_item_reference).and_return(true)
  end

  describe "PUT #update" do
    let(:base_params) { { profile_item_id: 1, reference_id: 99 } }

    context "when annotation is blank" do
      it "renders :update_failed with a validation message" do
        put :update, params: base_params.merge(profile_item_reference: { annotation: "" }), format: :turbo_stream

        expect(assigns(:message)).to eq("Annotation can't be blank. Use 'Delete annotation' to remove it.")
        expect(response).to render_template(:update_failed)
        expect(response).to have_http_status(:unprocessable_content)
      end

      it "does not update the record" do
        allow(profile_item_reference).to receive(:annotation).and_return("Existing annotation")
        expect(profile_item_reference).not_to receive(:update)

        put :update, params: base_params.merge(profile_item_reference: { annotation: "" }), format: :turbo_stream
      end
    end

    context "when annotation is unchanged" do
      before do
        allow(profile_item_reference).to receive(:annotation).and_return("same text")
      end

      it "renders :update with no change message without updating" do
        expect(profile_item_reference).not_to receive(:update)

        put :update, params: base_params.merge(profile_item_reference: { annotation: "same text" }), format: :turbo_stream

        expect(assigns(:message)).to eq("No change")
        expect(response).to render_template(:update)
      end
    end

    context "when annotation is changed to a valid value" do
      before do
        allow(profile_item_reference).to receive(:annotation).and_return("old text")
        allow(profile_item_reference).to receive(:update).and_return(true)
      end

      it "saves and renders :update with saved message" do
        put :update, params: base_params.merge(profile_item_reference: { annotation: "new text" }), format: :turbo_stream

        expect(profile_item_reference).to have_received(:update).with(hash_including(annotation: "new text"))
        expect(assigns(:message)).to eq("Saved")
        expect(response).to render_template(:update)
      end
    end

    context "when an error occurs during update" do
      before do
        allow(profile_item_reference).to receive(:annotation).and_return("old text")
        allow(profile_item_reference).to receive(:update).and_raise(StandardError, "DB error")
      end

      it "renders :update_failed with the error message" do
        put :update, params: base_params.merge(profile_item_reference: { annotation: "new text" }), format: :turbo_stream

        expect(assigns(:message)).to eq("DB error")
        expect(response).to render_template(:update_failed)
        expect(response).to have_http_status(:unprocessable_content)
      end
    end

    context "for non-authorized user" do
      before do
        allow(controller).to receive(:can?).with(:manage, profile_item_reference).and_return(false)
      end

      it "returns forbidden" do
        put :update, params: base_params.merge(profile_item_reference: { annotation: "new text" }), format: :turbo_stream
        expect(response).to have_http_status(:forbidden)
      end
    end
  end
end
