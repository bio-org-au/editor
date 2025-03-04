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
    include_context "#group_check?", :profile_v2?, "apni"
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

  describe "#registered_user" do
    let(:username) { 'testuser' }
    let(:full_name) { 'Test User' }
    let(:groups) { ['group1', 'group2'] }

    subject { described_class.new(username:, full_name:, groups:).registered_user }

    context 'when the user is already registered' do
      let!(:registered_user) { FactoryBot.create(:user, user_name: username) }

      it 'returns the registered user' do
        expect(subject).to eq(registered_user)
      end
    end

    context 'when the user is not registered' do
      it 'creates and returns a new user' do
        expect {
          subject
        }.to change(User, :count).by(1)

        new_user = User.find_by(user_name: username)
        expect(new_user).not_to be_nil
        expect(new_user.family_name).to eq('User')
        expect(new_user.given_name).to eq('Test')
      end

      it 'returns the newly created user' do
        new_user = subject
        expect(new_user).to be_a(User)
        expect(new_user.user_name).to eq(username)
        expect(new_user.family_name).to eq('User')
        expect(new_user.given_name).to eq('Test')
      end
    end
  end

  describe '#with_role?' do
    let(:username) { 'testuser' }
    let(:full_name) { 'Test User' }
    let(:groups) { ['group1', 'group2'] }

    let!(:user) { FactoryBot.create(:user, user_name: username) }
    let!(:role_type) { FactoryBot.create(:role_type, name: 'admin') }
    let!(:product_role) { FactoryBot.create(:user_product_role, user: user, role_type: role_type) }

    let(:session_user) { FactoryBot.create(:session_user, username: username, groups: groups) }

    context 'when the user is present' do
      context 'when the user has the requested role' do
        it 'returns true' do
          expect(session_user.with_role?("admin")).to be true
        end
      end

      context 'when the user does not have the requested role' do
        it 'returns false' do
          expect(session_user.with_role?('editor')).to be false
        end
      end
    end

    context 'when the user is not present' do
      before do
        allow(session_user).to receive(:user).and_return(nil)
      end

      it 'returns nil' do
        expect(session_user.with_role?('admin')).to be_nil
      end
    end
  end

  describe "#user" do
    let(:username) { "test" }
    let!(:user) { FactoryBot.create(:user, user_name: username) }
    let!(:session_user) { FactoryBot.create(:session_user, username: "test", groups: ["login"]) }

    subject { session_user.user }

    context "when username matches a user's user name" do
      it "returns the user object" do
        expect(subject).to eq(user)
      end
    end

    context "when username does not match a user's user name" do
      let(:username) { "bob" }
      it "returns nil" do
        expect(subject).to eq(nil)
      end
    end
  end
end
