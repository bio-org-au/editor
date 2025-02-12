require 'rails_helper'

RSpec.describe Ability, type: :model do
  describe "#profile_v2_viewer" do
    let(:user) { FactoryBot.create(:user) }

    subject { described_class.new(user) }

    describe "#profile_v2_auth" do
      context "for user with profile_v2" do
        before { allow(user).to receive(:profile_v2?).and_return(true) }
        it "grants all access to profile_items" do
          expect(subject.can?("profile_items", :all)).to eq true
          expect(subject.can?(:manage, :profile_v2)).to eq true
        end

        it "grants all access to profile_item_annotations" do
          expect(subject.can?("profile_item_annotations", :all)).to eq true
        end

        it "grants acces to profile v2 tab of instance" do
          expect(subject.can?("instances", "tab_profile_v2")).to eq true
        end

        it "grants acces to profile_texts" do
          expect(subject.can?("profile_texts", :all)).to eq true
        end

        it "grants acces to profile_item_references" do
          expect(subject.can?("profile_item_references", :all)).to eq true
        end

        it "grants acces to typeahead citation of a reference" do
          expect(subject.can?("references", "typeahead_on_citation")).to eq true
        end
      end
    end
  end
end
