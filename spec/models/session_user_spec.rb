# frozen_string_literal: true

require 'rails_helper'

shared_context "#group_check?" do |method_name, group|
  subject { session_user.send(method_name) }

  context "when group includes #{group}" do
    let(:session_user) { FactoryBot.create(:session_user, groups: [group]) }
    it "returns true" do
      expect(subject).to eq(true)
    end
  end

  context "when group does not include #{method_name.to_s.downcase}" do
    let(:session_user) { FactoryBot.create(:session_user, groups: ["something"]) }
    it "returns false" do
      expect(subject).to eq(false)
    end
  end
end

RSpec.describe SessionUser, type: :model do

  describe ".validations" do
    let(:params) { {username: nil, full_name: nil, groups: nil} }

    subject { described_class.new(params) }

    it "is invalid without a username" do
      expect(subject).not_to be_valid
      expect(subject.errors[:username]).to include("can't be blank")
    end

    it "is invalid without a full_name" do
      expect(subject).not_to be_valid
      expect(subject.errors[:full_name]).to include("can't be blank")
    end

    it "is invalid without a group" do
      expect(subject).not_to be_valid
      expect(subject.errors[:groups]).to include("can't be blank")
    end
  end

  describe ".accessors" do
    let(:session_user) { FactoryBot.create(:session_user, :admin, username: "test", full_name: "test user") }

    it "can access the username" do
      expect(session_user.username).to eq "test"
    end

    it "can access the full_name" do
      expect(session_user.full_name).to eq "test user"
    end

    it "can access the groups" do
      expect(session_user.groups).to eq ["admin"]
    end
  end

  describe "#profile_v2_context" do
    let(:session_user) { FactoryBot.create(:session_user) }

    subject { session_user.profile_v2_context }

    context "for foa group" do
      it "return the foa profile context" do
        allow_any_instance_of(SessionUser).to receive(:groups).and_return('foa')
        expect(subject.class).to eq Users::ProfileContexts::Foa
      end
    end

    context "for apni group" do
      it "return the foa profile context" do
        allow_any_instance_of(SessionUser).to receive(:groups).and_return('apni')
        expect(subject.class).to eq Users::ProfileContexts::Apni
      end
    end

    context "for non-profile group" do
      it "return the foa profile context" do
        allow_any_instance_of(SessionUser).to receive(:groups).and_return('other-product')
        expect(subject.class).to eq Users::ProfileContexts::Apni
      end
    end
  end

  describe "#profile_v2?" do
    include_context "#group_check?", :profile_v2?, "foa"
  end

  describe "#edit?" do
   include_context "#group_check?", :edit?, "edit"
  end

  describe "#admin?" do
    include_context "#group_check?", :admin?, "admin"
  end

  describe "#qa?" do
    include_context "#group_check?", :qa?, "QA"
  end

  describe "#reviewer?" do
    include_context "#group_check?", :reviewer?, "taxonomic-review"
  end

  describe "#compiler?" do
    include_context "#group_check?", :compiler?, "treebuilder"
  end

  describe "#batch_loader?" do
    include_context "#group_check?", :batch_loader?, "batch-loader"
  end

  describe "#loader_2_tab_loader?" do
    include_context "#group_check?", :loader_2_tab_loader?, "loader-2-tab"
  end

  describe "#foa_context_group?" do
    include_context "#group_check?", :foa_context_group?, "foa-context-group"
  end

  describe "#v2_profile_instance_edit?" do
    include_context "#group_check?", :v2_profile_instance_edit?, "v2-profile-instance-edit"
  end
end
