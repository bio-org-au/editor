require "rails_helper"

RSpec.describe Users::ProfileContexts::Apni, type: :service do
  let(:groups) { ["apni"] }
  let(:user) { FactoryBot.create(:user, groups: groups) }

  subject { described_class.new(user) }

  describe ".initialize" do
    it "has a logger instance variable" do
      expect(subject.instance_variable_get(:@logger)).to eq Rails.logger
    end

    it "has a product" do
      expect(subject.product).to eq "APNI"
    end

    it "has a user" do
      expect(subject.user).to eq user
    end
  end

  describe "#profile_view_allowed?" do
    it "returns true" do
      expect(subject.profile_view_allowed?).to eq true
    end
  end

  describe "#instance_edit_allowed?" do
    it "returns false" do
      expect(subject.instance_edit_allowed?).to eq false
    end
  end

  describe "#copy_instance_allowed?" do
    it "returns true" do
      expect(subject.copy_instance_allowed?).to eq true    end
  end

  # describe "#instance_editor?" do
  #   context "for v2-profile-instance-edit group" do
  #     let(:groups) { ["apni", "v2-profile-instance-edit"] }
  #     it "returns true" do
  #       expect(subject.instance_editor?).to eq true
  #     end
  #   end
    
  #   context "for non v2-profile-instance-edit group" do
  #     it "returns false" do
  #       expect(subject.instance_editor?).to eq false
  #     end
  #   end
  # end

  context "for undefined method" do
    it "return nil" do
      expect(subject.unknown_method).to eq nil
    end
  end
end