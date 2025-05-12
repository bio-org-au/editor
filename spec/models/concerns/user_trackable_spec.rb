require 'rails_helper'


class TestModel < ActiveRecord::Base
  self.table_name = "users"
  include UserTrackable

  attr_accessor :current_user
end

RSpec.describe UserTrackable, type: :model do
  describe "callbacks" do
    let(:user) { double("User", user_name: "test_user") }
    let(:mocked_model) { TestModel.new(user_name: "test user", family_name: "family name") }

    context "when current_user is nil" do
      before { mocked_model.current_user = nil }

      context "when created_by is not set" do
        it "raises a db not null violation" do
          expect {
            mocked_model.save
          }.to raise_error(ActiveRecord::NotNullViolation)
        end
      end

      context "when created_by is already set" do
        let(:mocked_model) { TestModel.create(user_name: "testuser", family_name: "family name", created_by: "tester", updated_by: "tester") }

        before { mocked_model.user_name = "new_name"}

        it "does not not change created_by" do
          mocked_model.save
          expect(mocked_model.created_by).to eq("tester")
        end

        it "does not change updated_by" do
          mocked_model.save
          expect(mocked_model.updated_by).to eq("tester")
        end
      end
    end

    context "when current_user is present" do
      before { mocked_model.current_user = user }

      it "sets created_by to current_user's user_name" do
        mocked_model.save
        expect(mocked_model.created_by).to eq(user.user_name)
      end

      it "does not overwrite created_by if already set" do
        mocked_model.save
        mocked_model.user_name = "new_name"
        mocked_model.current_user = double("User", user_name: "other_user")
        mocked_model.save
        expect(mocked_model.created_by).to eq(user.user_name)
      end

      it "sets updated_by to current_user's user_name" do
        mocked_model.save
        expect(mocked_model.updated_by).to eq(user.user_name)
      end
    end
  end
end
