require 'rails_helper'

RSpec.describe Users::ProductRoles::CreateService, type: :service do
  let(:user) { create(:user, default_product_context_id: nil) }
  let(:role) { create(:role) }
  let(:product) { create(:product, context_id: 1) }
  let(:product_role) { create(:product_role, product: product, role: role) }
  let(:username) { "testuser" }

  describe "#execute" do
    subject { described_class.new(user_id: user.id, product_role_id: product_role.id, username: username) }

    it "creates a new user_product_role" do
      expect { subject.execute }.to change(User::ProductRole, :count).by(1)
    end

    it "sets the user_product_role attribute" do
      subject.execute
      expect(subject.user_product_role).to be_a(User::ProductRole)
      expect(subject.user_product_role.user_id).to eq(user.id)
      expect(subject.user_product_role.product_role_id).to eq(product_role.id)
    end

    it "does not add any errors" do
      subject.execute

      expect(subject.errors).to be_empty
    end

    context "when user has no default product context" do
      it "sets the default product context from the product" do
        subject.execute
        expect(user.reload.default_product_context_id).to eq(product.context_id)
      end
    end

    context "when user already has a default product context" do
      let(:user) { create(:user, default_product_context_id: product.context_id) }

      it "does not change the default product context" do
        subject.execute

        expect(user.reload.default_product_context_id).to eq(product.context_id)
      end
    end

    context "when the service is invalid" do
      context "when user does not exist" do
        it "adds an error" do
          service = described_class.new(user_id: -1, product_role_id: product_role.id, username: username)
          expect(service).not_to be_valid
          expect(service.errors[:base]).to include("User with ID -1 does not exist")
        end

        it "does not create a user_product_role" do
          service = described_class.new(user_id: -1, product_role_id: product_role.id, username: username)
          expect { service.execute }.not_to change(User::ProductRole, :count)
        end
      end

      context "when product_role does not exist" do
        it "adds an error" do
          service = described_class.new(user_id: user.id, product_role_id: -1, username: username)
          expect(service).not_to be_valid
          expect(service.errors[:base]).to include("Product role with ID -1 does not exist")
        end

        it "does not create a user_product_role" do
          service = described_class.new(user_id: user.id, product_role_id: -1, username: username)
          expect { service.execute }.not_to change(User::ProductRole, :count)
        end
      end

      context "when user_product_role already exists" do
        before do
          create(:user_product_role, user: user, product_role: product_role)
        end

        it "does not create a duplicate user_product_role" do
          expect { subject.execute }.not_to change(User::ProductRole, :count)
        end

        it "adds validation errors from the model" do
          subject.execute

          expect(subject.errors[:base]).not_to be_empty
        end
      end

      context "when user save fails while setting default context" do
        before do
          allow(User::ProductRole).to receive(:create).and_raise(StandardError.new("Some error"))
        end

        it "adds an error" do
          subject.execute
          expect(subject.errors[:base]).to include("Some error")
        end

        it "does not set the default product context" do
          subject.execute
          expect(user.reload.default_product_context_id).to be_nil
        end
      end
    end
  end
end
