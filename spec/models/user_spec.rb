# frozen_string_literal: true

require "rails_helper"

RSpec.describe(User, type: :model) do
  describe "associations" do
    it { is_expected.to(have_many(:batch_reviewers).class_name("Loader::Batch::Reviewer").with_foreign_key("user_id")) }
    it { is_expected.to(have_many(:user_product_roles).class_name("User::ProductRole").with_foreign_key("user_id")) }
    it { is_expected.to(have_many(:product_roles).through(:user_product_roles)) }
    it { is_expected.to(have_many(:products).through(:product_roles)) }
    it { is_expected.to(have_many(:roles).through(:product_roles)) }
    it { is_expected.to(have_many(:user_product_role_vs)) }
  end

  describe "#role_names" do
    let(:user) { create(:user) }
    let!(:role1) { create(:role, name: "admin") }
    let!(:role2) { create(:role, name: "editor") }
    let!(:product) { create(:product) }
    let!(:product_role1) { create(:product_role, product:, role: role1) }
    let!(:product_role2) { create(:product_role, product:, role: role2) }
    let!(:user_product_role1) { create(:user_product_role, product_role: product_role1, user:) }
    let!(:user_product_role2) { create(:user_product_role, product_role: product_role2, user:) }

    it "returns an array of role names" do
      expect(user.role_names).to(match_array(["admin", "editor"]))
    end

    it "memoizes the result" do
      user.role_names
      expect(user.roles).not_to(receive(:pluck))
      user.role_names
    end

    context "when user has no roles" do
      let(:user_without_roles) { create(:user) }

      it "returns an empty array" do
        expect(user_without_roles.role_names).to(eq([]))
      end
    end
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

  describe "#grantable_product_roles_for_select" do
    let(:user) { create(:user) }
    let!(:admin_role) { create(:role, name: "admin") }
    let!(:editor_role) { create(:role, name: "editor") }
    let!(:reviewer_role) { create(:role, name: "reviewer") }
    let!(:product) { create(:product) }

    let!(:admin_product_role) { create(:product_role, product: product, role: admin_role) }
    let!(:editor_product_role) { create(:product_role, product: product, role: editor_role) }
    let!(:reviewer_product_role) { create(:product_role, product: product, role: reviewer_role) }

    before do
      allow(Product::Role).to receive(:non_admins).and_return([editor_product_role, reviewer_product_role])
    end

    context "when user has no product roles" do
      it "returns all non-admin product roles formatted for select" do
        result = user.grantable_product_roles_for_select

        expect(result).to match_array([
          ["#{product.name} editor product role", editor_product_role.id],
          ["#{product.name} reviewer product role", reviewer_product_role.id]
        ])
      end

      it "sorts roles by name alphabetically" do
        zebra_role = create(:role, name: "zebra")
        alpha_role = create(:role, name: "alpha")
        zebra_product_role = create(:product_role, product: product, role: zebra_role)
        alpha_product_role = create(:product_role, product: product, role: alpha_role)

        allow(Product::Role).to receive(:non_admins).and_return([zebra_product_role, alpha_product_role])

        result = user.grantable_product_roles_for_select

        expect(result).to eq([
          ["#{product.name} alpha product role", alpha_product_role.id],
          ["#{product.name} zebra product role", zebra_product_role.id]
        ])
      end
    end

    context "when user already has some product roles" do
      before do
        create(:user_product_role, user: user, product_role: editor_product_role)
      end

      it "excludes roles the user already has" do
        result = user.grantable_product_roles_for_select

        expect(result).to eq([["#{product.name} reviewer product role", reviewer_product_role.id]])
        expect(result.map(&:first)).not_to include("#{product.name} editor product role")
      end
    end

    context "when user has all non-admin product roles" do
      before do
        create(:user_product_role, user: user, product_role: editor_product_role)
        create(:user_product_role, user: user, product_role: reviewer_product_role)
      end

      it "returns empty array" do
        result = user.grantable_product_roles_for_select

        expect(result).to eq([])
      end
    end

    context "with multiple products" do
      let!(:product2) { create(:product) }
      let!(:editor_product_role2) { create(:product_role, product: product2, role: editor_role) }
      let!(:reviewer_product_role2) { create(:product_role, product: product2, role: reviewer_role) }

      before do
        allow(Product::Role).to receive(:non_admins).and_return([
          editor_product_role, reviewer_product_role,
          editor_product_role2, reviewer_product_role2
        ])
      end

      it "includes product roles from all products" do
        result = user.grantable_product_roles_for_select

        expect(result.size).to eq(4)
        expect(result.map(&:first)).to match_array([
          "#{product.name} editor product role",
          "#{product.name} reviewer product role",
          "#{product2.name} editor product role",
          "#{product2.name} reviewer product role"
        ])
      end

      it "excludes user's existing roles only for specific product role combinations" do
        create(:user_product_role, user: user, product_role: editor_product_role)

        result = user.grantable_product_roles_for_select

        expect(result.size).to eq(3)
        role_ids = result.map(&:last)
        expect(role_ids).not_to include(editor_product_role.id)
        expect(role_ids).to include(editor_product_role2.id)
      end
    end

    context "when current_user is a product admin" do
      let(:product_admin_user) { create(:user) }
      let(:session_user) { create(:session_user) }
      let(:admin_role) { create(:role, name: "admin") }

      let(:foa_product) { create(:product, name: "FOA") }
      let(:apc_product) { create(:product, name: "APC") }

      let(:foa_admin_product_role) { create(:product_role, product: foa_product, role: admin_role) }
      let(:foa_editor_product_role) { create(:product_role, product: foa_product, role: editor_role) }
      let(:apc_editor_product_role) { create(:product_role, product: apc_product, role: editor_role) }

      before do
        # Set up product admin user with FOA admin role
        create(:user_product_role, user: product_admin_user, product_role: foa_admin_product_role)

        allow(session_user).to receive(:with_role?).with('admin').and_return(true)
        allow(session_user).to receive(:user).and_return(product_admin_user)

        # Enable multi-product tabs feature
        allow(Rails.configuration).to receive(:try).with(:multi_product_tabs_enabled).and_return(true)

        allow(Product::Role).to receive(:non_admins).and_return([
          foa_editor_product_role, apc_editor_product_role
        ])
      end

      it "restricts available roles to products they have admin access to" do
        result = user.grantable_product_roles_for_select(session_user)

        expect(result).to eq([["FOA editor product role", foa_editor_product_role.id]])
        expect(result.map(&:first)).not_to include("APC editor product role")
      end

      it "excludes roles from products they don't have admin access to" do
        result = user.grantable_product_roles_for_select(session_user)

        role_names = result.map(&:first)
        expect(role_names).not_to include("APC editor product role")
      end

      context "when user already has some roles" do
        before do
          create(:user_product_role, user: user, product_role: foa_editor_product_role)
        end

        it "excludes existing roles from the filtered list" do
          result = user.grantable_product_roles_for_select(session_user)

          expect(result).to eq([])
        end
      end

      context "when multi_product_tabs_enabled is false" do
        before do
          allow(Rails.configuration).to receive(:try).with(:multi_product_tabs_enabled).and_return(false)
        end

        it "behaves like normal admin without restrictions" do
          result = user.grantable_product_roles_for_select(session_user)

          expect(result.size).to eq(2)
          expect(result.map(&:first)).to match_array(["FOA editor product role", "APC editor product role"])
        end
      end

      context "when current_user has multiple admin products" do
        let(:apni_product) { create(:product, name: "APNI") }
        let(:apni_admin_product_role) { create(:product_role, product: apni_product, role: admin_role) }
        let(:apni_editor_product_role) { create(:product_role, product: apni_product, role: editor_role) }

        before do
          create(:user_product_role, user: product_admin_user, product_role: apni_admin_product_role)

          allow(Product::Role).to receive(:non_admins).and_return([
            foa_editor_product_role, apc_editor_product_role, apni_editor_product_role
          ])
        end

        it "includes roles from all products they have admin access to" do
          result = user.grantable_product_roles_for_select(session_user)

          expect(result.size).to eq(2)
          expect(result.map(&:first)).to match_array(["FOA editor product role", "APNI editor product role"])
          expect(result.map(&:first)).not_to include("APC editor product role")
        end
      end
    end

    context "when current_user is not a product admin" do
      let(:regular_user) { create(:user) }
      let(:session_user) { create(:session_user) }

      before do
        allow(session_user).to receive(:with_role?).with('admin').and_return(false)
        allow(session_user).to receive(:user).and_return(regular_user)
      end

      it "behaves normally without restrictions" do
        result = user.grantable_product_roles_for_select(session_user)

        expect(result).to match_array([
          ["#{product.name} editor product role", editor_product_role.id],
          ["#{product.name} reviewer product role", reviewer_product_role.id]
        ])
      end
    end

    context "return format validation" do
      it "returns array of [name, id] pairs" do
        result = user.grantable_product_roles_for_select

        result.each do |item|
          expect(item).to be_an(Array)
          expect(item.size).to eq(2)
          expect(item.first).to be_a(String)
          expect(item.last).to be_an(Integer)
        end
      end
    end
  end
end
