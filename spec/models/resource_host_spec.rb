# frozen_string_literal: true

require "rails_helper"

RSpec.describe ResourceHost, type: :model do
  describe "associations" do
    it { is_expected.to have_many(:name_resources) }
  end

  describe "validations" do
    context "when all required fields are present" do
      let(:resource_host) { create(:resource_host) }

      it "is valid" do
        expect(resource_host).to be_valid
      end
    end

    context "when resolving_url is missing" do
      let(:resource_host) { build(:resource_host, resolving_url: nil) }

      it "is not valid" do
        expect(resource_host).not_to be_valid
        expect(resource_host.errors[:resolving_url]).to include("can't be blank")
      end
    end

    context "when rdf_id is missing" do
      let(:resource_host) { build(:resource_host, rdf_id: nil) }

      it "is not valid" do
        expect(resource_host).not_to be_valid
        expect(resource_host.errors[:rdf_id]).to include("can't be blank")
      end
    end
  end

  describe "scopes" do
    describe ".for_names" do
      let!(:name_resource_host) { create(:resource_host, for_name: true) }
      let!(:reference_resource_host) { create(:resource_host, for_name: false, for_reference: true) }

      it "returns only resource hosts with for_name set to true" do
        result = ResourceHost.for_names
        expect(result).to include(name_resource_host)
        expect(result).not_to include(reference_resource_host)
      end
    end
  end

  describe "UserTrackable concern" do
    let(:user) { double("User", user_name: "test_user") }

    context "when current_user is present on creation" do
      let(:resource_host) { build(:resource_host) }

      it "sets created_by from current_user" do
        resource_host.created_by = nil
        resource_host.updated_by = nil
        resource_host.current_user = user
        resource_host.save
        expect(resource_host.created_by).to eq("test_user")
      end

      it "sets updated_by from current_user" do
        resource_host.created_by = nil
        resource_host.updated_by = nil
        resource_host.current_user = user
        resource_host.save
        expect(resource_host.updated_by).to eq("test_user")
      end
    end

    context "when current_user is present on update" do
      let(:new_user) { double("User", user_name: "new_user") }
      let(:resource_host) { create(:resource_host, created_by: "original_user", updated_by: "original_user") }

      before do
        resource_host.current_user = new_user
        resource_host.name = "Updated Name"
        resource_host.save
      end

      it "does not overwrite created_by" do
        expect(resource_host.created_by).to eq("original_user")
      end

      it "updates updated_by with current_user" do
        expect(resource_host.updated_by).to eq("new_user")
      end
    end
  end
end
