# frozen_string_literal: true

require "rails_helper"

RSpec.describe ProfileItemReferences::AnnotationsController, type: :controller do
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
    allow(Profile::ProfileItemReference).to receive(:find_by!).and_return(profile_item_reference)
  end

  describe "DELETE #destroy" do
    let(:composite_id) { "1_99" }

    context "for authorized user" do
      before do
        allow(controller).to receive(:can?).with(:manage, profile_item_reference).and_return(true)
        allow(profile_item_reference).to receive(:update!).and_return(true)
      end

      it "clears the annotation and renders :delete" do
        delete :destroy, params: { id: composite_id }, format: :turbo_stream

        expect(profile_item_reference).to have_received(:update!).with(annotation: nil, updated_by: session_user.username)
        expect(assigns(:message)).to eq("Annotation deleted")
        expect(response).to render_template(:delete)
        expect(response.media_type).to eq("text/vnd.turbo-stream.html")
      end

      context "when an error occurs during update" do
        before do
          allow(profile_item_reference).to receive(:update!).and_raise(StandardError, "Update failed")
        end

        it "renders :delete_failed with an error message" do
          delete :destroy, params: { id: composite_id }, format: :turbo_stream

          expect(assigns(:message)).to eq("Update failed")
          expect(response).to render_template(:delete_failed)
          expect(response).to have_http_status(:unprocessable_content)
        end
      end
    end

    context "for non-authorized user" do
      before do
        allow(controller).to receive(:can?).with(:manage, profile_item_reference).and_return(false)
      end

      it "returns forbidden" do
        delete :destroy, params: { id: composite_id }, format: :turbo_stream
        expect(response).to have_http_status(:forbidden)
      end

      it "does not clear the annotation" do
        allow(profile_item_reference).to receive(:update!)
        delete :destroy, params: { id: composite_id }, format: :turbo_stream
        expect(profile_item_reference).not_to have_received(:update!)
      end
    end
  end
end
