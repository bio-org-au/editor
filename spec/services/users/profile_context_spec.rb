require "rails_helper"

RSpec.describe Users::ProfileContext, type: :service do
  let(:groups) { ["foa"] }
  let(:user) { FactoryBot.create(:user, groups: groups) }

  subject { described_class.new(user) }

  describe ".initialize" do

    before {allow(Rails.configuration).to receive(:try).with('profile_v2_aware').and_return(true) }

    it "instantiates a user" do
      expect(subject.instance_variable_get(:@user)).to eq(user)
    end

    context "for when a user group is given" do
      context "when profile_v2_aware is disabled" do
        before {allow(Rails.configuration).to receive(:try).with('profile_v2_aware').and_return(false) }
        it "instantiates the default context" do
          expect(subject.instance_variable_get(:@context).class).to eq Users::ProfileContexts::Base
        end
      end

      context "for foa" do
        it "instantiate an FOA context for foa group" do
          expect(subject.instance_variable_get(:@context).class).to eq Users::ProfileContexts::Foa
        end
      end

      context "for non-foa" do
        let(:groups) { ["non-foa"] }
        it "instantiate an APNI context for non-foa group" do
          expect(subject.instance_variable_get(:@context).class).to eq Users::ProfileContexts::Apni
        end
      end
    end
  end
end