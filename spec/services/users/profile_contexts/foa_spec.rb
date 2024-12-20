require "rails_helper"

RSpec.describe Users::ProfileContexts::Foa, type: :service do
  let(:groups) { ["foa"] }
  let(:user) { FactoryBot.create(:user, groups: groups) }

  subject { described_class.new(user) }

  describe ".initialize" do
    it "has a logger instance variable" do
      expect(subject.instance_variable_get(:@logger)).to eq Rails.logger
    end

    it "has a product" do
      expect(subject.product).to eq "FOA"
    end

    it "has a user" do
      expect(subject.user).to eq user
    end
  end

  context "for undefined method" do
    it "return nil" do
      expect(subject.unknown_method).to eq nil
    end
  end

  describe "#profile_view_allowed?" do
    it "returns true" do
      expect(subject.profile_view_allowed?).to eq true
    end
  end

  describe "#profile_edit_allowed?" do
    context "for v2-profile-instance-edit group" do
      it "returns true" do
        allow(subject).to receive(:instance_edit_allowed?).and_return(true)
        expect(subject.profile_edit_allowed?).to eq true
      end
    end
    
    context "for non v2-profile-instance-edit group" do
      it "returns false" do
        allow(subject).to receive(:instance_edit_allowed?).and_return(false)
        expect(subject.profile_edit_allowed?).to eq false
      end
    end
  end

  describe "#instance_edit_allowed?" do
    context "for v2-profile-instance-edit group" do
      let(:groups) { ["foa", "v2-profile-instance-edit"] }
      it "returns true" do
        expect(subject.instance_edit_allowed?).to eq true
      end
    end
    
    context "for non v2-profile-instance-edit group" do
      it "returns false" do
        expect(subject.instance_edit_allowed?).to eq false
      end
    end
  end

  describe "#copy_instance_allowed?" do
    it "returns true" do
      expect(subject.copy_instance_allowed?).to eq true
    end
  end

  describe "#copy_instance_tab" do
    context "with invalid arguments" do
      it "raises an error" do
        expect{subject.copy_instance_tab}.to raise_error(ArgumentError)
      end
    end

    context "with valid arguments" do
      let(:instance) { FactoryBot.create(:instance) }
      context "when instance is draft" do
        it "returns nil" do
          allow(instance).to receive(:draft).and_return(true)
          expect(subject.copy_instance_tab(instance)).to eq nil
        end
      end
      
      context "when instance is not draft" do
        it "returns tab_copy_to_new_profile_v2" do
          allow(instance).to receive(:draft).and_return(false)
          expect(subject.copy_instance_tab(instance)).to eq "tab_copy_to_new_profile_v2"
        end
      end
    end
  end
  
end