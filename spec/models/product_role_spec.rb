# frozen_string_literal: true

require "rails_helper"

RSpec.describe Product::Role, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:role) }
    it { is_expected.to belong_to(:product) }
    it { is_expected.to have_many(:user_product_roles).class_name("User::ProductRole").with_foreign_key(:product_role_id) }
    it { is_expected.to have_many(:user_product_role_vs) }
  end



  describe "scopes" do
    let!(:admin_role) { create(:role, name: "admin") }
    let!(:editor_role) { create(:role, name: "editor") }
    let!(:viewer_role) { create(:role, name: "viewer") }

    let!(:product) { create(:product) }

    let!(:admin_product_role) { create(:product_role, role: admin_role, product: product) }
    let!(:editor_product_role) { create(:product_role, role: editor_role, product: product) }
    let!(:viewer_product_role) { create(:product_role, role: viewer_role, product: product) }

    describe ".admins" do
      it "returns only product roles with admin role" do
        expect(described_class.admins).to contain_exactly(admin_product_role)
      end

      it "does not return non-admin product roles" do
        expect(described_class.admins).not_to include(editor_product_role, viewer_product_role)
      end

      it "returns empty collection when no admin product roles exist" do
        admin_product_role.destroy!
        expect(described_class.admins).to be_empty
      end

      it "handles multiple admin product roles" do
        another_product = create(:product)
        another_admin_product_role = create(:product_role, role: admin_role, product: another_product)

        expect(described_class.admins).to contain_exactly(admin_product_role, another_admin_product_role)
      end
    end

    describe ".non_admins" do
      it "returns product roles that are not admin roles" do
        expect(described_class.non_admins).to contain_exactly(editor_product_role, viewer_product_role)
      end

      it "does not return admin product roles" do
        expect(described_class.non_admins).not_to include(admin_product_role)
      end

      it "returns all product roles when no admin roles exist" do
        admin_product_role.destroy!
        expect(described_class.non_admins).to contain_exactly(editor_product_role, viewer_product_role)
      end

      it "handles case when only admin product roles exist" do
        editor_product_role.destroy!
        viewer_product_role.destroy!
        expect(described_class.non_admins).to be_empty
      end
    end

    describe "scope combinations" do
      it "ensures admins and non_admins scopes are mutually exclusive" do
        all_product_roles = [admin_product_role, editor_product_role, viewer_product_role]
        admins = described_class.admins.to_a
        non_admins = described_class.non_admins.to_a

        expect(admins & non_admins).to be_empty
        expect((admins + non_admins).sort_by(&:id)).to eq(all_product_roles.sort_by(&:id))
      end
    end
  end

  describe "#name" do
    let(:product) { create(:product, name: "Test Product") }
    let(:role) { create(:role, name: "editor") }
    let(:product_role) { create(:product_role, product: product, role: role) }

    it "returns a formatted name combining product and role names" do
      expect(product_role.name).to eq("Test Product editor product role")
    end
  end

  describe "database constraints" do
    it "enforces unique product-role combination" do
      product = create(:product)
      role = create(:role)
      create(:product_role, product: product, role: role)

      expect {
        create(:product_role, product: product, role: role)
      }.to raise_error(ActiveRecord::RecordNotUnique)
    end
  end
end
