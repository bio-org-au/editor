require 'rails_helper'

RSpec.describe Users::ProductRoles::DestroyService, type: :service do
  let!(:user) { create(:user, default_product_context_id: nil) }
  let(:role) { create(:role) }
  let(:product1) { create(:product, context_id: 1) }
  let(:product2) { create(:product, context_id: 2) }
  let(:product_role1) { create(:product_role, product: product1, role: role) }
  let(:product_role2) { create(:product_role, product: product2, role: role) }
  let!(:user_product_role1) { create(:user_product_role, user: user, product_role: product_role1) }

  describe "#execute" do
    subject { described_class.new(user_product_role: user_product_role1) }

    it "deletes the user_product_role" do
      expect { subject.execute }.to change(User::ProductRole, :count).by(-1)
    end

    it "does not add any errors when successful" do
      subject.execute

      expect(subject.errors).to be_empty
    end

    context "when user has other product roles remaining" do
      let!(:user_product_role2) { create(:user_product_role, user: user, product_role: product_role2) }

      it "sets the default product context to the first available product context" do
        subject.execute

        expect(user.reload.default_product_context_id).to eq(product_role2.product.context_id)
      end
    end

    context "when user has no other product roles remaining" do
      it "sets the default product context to main context id" do
        subject.execute

        expect(user.reload.default_product_context_id).to eq(Users::ProductRoles::DestroyService::MAIN_CONTEXT_ID)
      end
    end

    context "when user_product_role destroy fails" do
      before do
        allow(user_product_role1).to receive(:destroy).and_return(false)
        allow(user_product_role1).to receive_message_chain(:errors, :full_messages).and_return(["Cannot destroy"])
      end

      it "adds an error message" do
        subject.execute

        expect(subject.errors[:base]).to include("Cannot destroy")
      end

      it "does not attempt to set default context" do
        subject.execute
        expect(subject).not_to receive(:set_default_context)
      end
    end
  end
end
