# frozen_string_literal: true

require "rails_helper"

RSpec.describe(User, type: :model) do
  describe "associations" do
    it { is_expected.to(have_many(:batch_reviewers).class_name("Loader::Batch::Reviewer").with_foreign_key("user_id")) }
    it { is_expected.to(have_many(:user_product_roles).class_name("User::ProductRole").with_foreign_key("user_id")) }
    it { is_expected.to(have_many(:product_roles).through(:user_product_roles)) }
    it { is_expected.to(have_many(:products).through(:product_roles)) }
    it { is_expected.to(have_many(:roles).through(:product_roles)) }
  end

  describe "#is?" do
    let(:user) { FactoryBot.create(:user) }
    let!(:role) { FactoryBot.create(:role, name: "admin") }
    let!(:product) { FactoryBot.create(:product) }
    let!(:product_role) { FactoryBot.create(:product_role, product:, role:) }
    let!(:user_product_role) { FactoryBot.create(:user_product_role, product_role:, user:) }

    context "when the user has the requested role type" do
      it "returns true" do
        expect(user.is?("admin")).to(be(true))
      end
    end

    context "when the user does not have the requested role type" do
      it "returns false" do
        expect(user.is?("editor")).to(be(false))
      end
    end
  end

  describe "#available_product_from_roles" do
    let!(:role1) { create(:role, name: "draft-editor") }
    let!(:role2) { create(:role, name: "profile-editor") }

    let!(:product1) { create(:product, name: "FOO") }
    let!(:product2) { create(:product, name: "BAR") }

    let!(:user) { create(:user, user_name: "testuser", given_name: "Test", family_name: "User", created_by: "Tester", updated_by: "Tester") }

    let!(:user_product_role1) { create(:user_product_role, user: user, product: product1, role: role1) }
    let!(:user_product_role2) { create(:user_product_role, user: user, product: product2, role: role2) }

    it "returns the first product for allowed roles" do
      expect(user.available_product_from_roles).to(eq(product1))
    end
  end

  describe "#available_products_from_roles" do
    let!(:role1) { create(:role, name: "draft-editor") }
    let!(:role2) { create(:role, name: "profile-editor") }
    let!(:role3) { create(:role, name: "other-editor") }

    let!(:product1) { create(:product, name: "FOO") }
    let!(:product2) { create(:product, name: "BAR") }
    let!(:product3) { create(:product, name: "CAN") }

    let!(:user) { create(:user, user_name: "testuser", given_name: "Test", family_name: "User", created_by: "Tester", updated_by: "Tester") }

    let!(:user_product_role1) { create(:user_product_role, user: user, product: product1, role: role1) }
    let!(:user_product_role2) { create(:user_product_role, user: user, product: product2, role: role2) }
    let!(:user_product_role3) { create(:user_product_role, user: user, product: product3, role: role3) }

    it "returns all unique products for all roles" do
      expect(user.available_products_from_roles).to(match_array([product1, product2, product3]))
    end

    it "returns unique products only" do
      test_role = create(:role, name: "test-editor")
      create(:user_product_role, user: user, product: product1, role: test_role)

      expect(user.available_products_from_roles.count(product1)).to(eq(1))
    end

    it "sorts products by context and name" do
      product1.update(context_id: 2, context_sort_order: 2)
      product2.update(context_id: 1, context_sort_order: 1)
      product3.update(context_id: 1, context_sort_order: 2)

      expect(user.available_products_from_roles).to(eq([product2, product3, product1]))
    end
  end
end
