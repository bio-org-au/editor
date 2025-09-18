# frozen_string_literal: true

require "rails_helper"

RSpec.describe(ApplicationHelper, type: :helper) do
  describe "#sorted_product_roles" do
    context "when user is nil" do
      it "returns an empty array" do
        expect(helper.sorted_product_roles(nil)).to(eq([]))
      end
    end

    context "when user has no product_roles" do
      let(:user) { double("User", product_roles: double("ProductRoles", includes: [])) }

      it "returns an empty array" do
        expect(helper.sorted_product_roles(user)).to(eq([]))
      end
    end

    context "when user has product_roles" do
      let(:product_a) { double("Product", name: "APC") }
      let(:product_z) { double("Product", name: "ZZZ") }
      let(:product_b) { double("Product", name: "BOR") }

      let(:role_editor) { double("Role", name: "Editor") }
      let(:role_admin) { double("Role", name: "Admin") }
      let(:role_viewer) { double("Role", name: "Viewer") }

      let(:product_role_1) { double("ProductRole", product: product_z, role: role_editor) }
      let(:product_role_2) { double("ProductRole", product: product_a, role: role_viewer) }
      let(:product_role_3) { double("ProductRole", product: product_a, role: role_admin) }
      let(:product_role_4) { double("ProductRole", product: product_b, role: role_editor) }

      let(:unsorted_product_roles) { [product_role_1, product_role_2, product_role_3, product_role_4] }
      let(:product_roles_relation) { double("ProductRoles", includes: unsorted_product_roles) }
      let(:user) { double("User", product_roles: product_roles_relation) }

      it "sorts product_roles by product name then role name ascending" do
        result = helper.sorted_product_roles(user)

        expect(result).to(eq([
          product_role_3, # APC Admin
          product_role_2, # APC Viewer
          product_role_4, # BOR Editor
          product_role_1  # ZZZ Editor
        ]))
      end

      it "includes products and roles" do
        expect(product_roles_relation).to(receive(:includes).with(:product, :role))
        helper.sorted_product_roles(user)
      end
    end

    context "when user has product_roles with same product names" do
      let(:product_same) { double("Product", name: "FOA") }

      let(:role_admin) { double("Role", name: "Admin") }
      let(:role_editor) { double("Role", name: "Editor") }
      let(:role_viewer) { double("Role", name: "Viewer") }

      let(:product_role_1) { double("ProductRole", product: product_same, role: role_viewer) }
      let(:product_role_2) { double("ProductRole", product: product_same, role: role_admin) }
      let(:product_role_3) { double("ProductRole", product: product_same, role: role_editor) }

      let(:unsorted_product_roles) { [product_role_1, product_role_2, product_role_3] }
      let(:product_roles_relation) { double("ProductRoles", includes: unsorted_product_roles) }
      let(:user) { double("User", product_roles: product_roles_relation) }

      it "sorts by role name when product names are the same" do
        result = helper.sorted_product_roles(user)

        expect(result).to(eq([
          product_role_2, # FOA Admin
          product_role_3, # FOA Editor
          product_role_1  # FOA Viewer
        ]))
      end
    end

    context "when user has product_roles with mixed case names" do
      let(:product_lower) { double("Product", name: "apc") }
      let(:product_upper) { double("Product", name: "BOR") }

      let(:role_lower) { double("Role", name: "admin") }
      let(:role_upper) { double("Role", name: "Editor") }

      let(:product_role_1) { double("ProductRole", product: product_upper, role: role_lower) }
      let(:product_role_2) { double("ProductRole", product: product_lower, role: role_upper) }

      let(:unsorted_product_roles) { [product_role_1, product_role_2] }
      let(:product_roles_relation) { double("ProductRoles", includes: unsorted_product_roles) }
      let(:user) { double("User", product_roles: product_roles_relation) }

      it "sorts case-sensitively" do
        result = helper.sorted_product_roles(user)

        expect(result).to(eq([
          product_role_1, # BOR admin (uppercase B comes before lowercase a)
          product_role_2  # apc Editor
        ]))
      end
    end
  end
end

