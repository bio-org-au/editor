RSpec.describe Users::ProfileContexts::ApniAccess, type: :model do
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

  describe "#viewer?" do
    it "returns true" do
      expect(subject.viewer?).to eq true
    end
  end

  describe "#editor?" do
    it "returns false" do
      expect(subject.editor?).to eq false
    end
  end

  describe "#instance_editor?" do
    context "for v2-profile-instance-edit group" do
      let(:groups) { ["apni", "v2-profile-instance-edit"] }
      it "returns true" do
        expect(subject.instance_editor?).to eq true
      end
    end
    
    context "for non v2-profile-instance-edit group" do
      it "returns false" do
        expect(subject.instance_editor?).to eq false
      end
    end
  end

  context "for undefined method" do
    it "return nil" do
      expect(subject.unknown_method).to eq nil
    end
  end
end