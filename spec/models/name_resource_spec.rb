# frozen_string_literal: true

require "rails_helper"

RSpec.describe NameResource, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:name) }
    it { is_expected.to belong_to(:resource_host) }
  end

  describe "UserTrackable concern" do
    let(:user) { double("User", user_name: "test_user") }

    context "when current_user is present on creation" do
      let(:name) { create(:name) }
      let(:resource_host) { create(:resource_host) }
      let(:name_resource) { build(:name_resource, name: name, resource_host: resource_host) }

      it "sets created_by from current_user" do
        name_resource.created_by = nil
        name_resource.updated_by = nil
        name_resource.current_user = user
        name_resource.save
        expect(name_resource.created_by).to eq("test_user")
      end

      it "sets updated_by from current_user" do
        name_resource.created_by = nil
        name_resource.updated_by = nil
        name_resource.current_user = user
        name_resource.save
        expect(name_resource.updated_by).to eq("test_user")
      end
    end

    context "when current_user is present on update" do
      let(:new_user) { double("User", user_name: "new_user") }
      let(:name_resource) { create(:name_resource, created_by: "original_user", updated_by: "original_user") }

      before do
        name_resource.current_user = new_user
        name_resource.note = "Updated note"
        name_resource.save
      end

      it "does not overwrite created_by" do
        expect(name_resource.created_by).to eq("original_user")
      end

      it "updates updated_by with current_user" do
        expect(name_resource.updated_by).to eq("new_user")
      end
    end
  end
end
