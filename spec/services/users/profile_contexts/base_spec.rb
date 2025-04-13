require "rails_helper"

RSpec.describe Users::ProfileContexts::Base, type: :service do
  let(:groups) { ["non-profile-product"] }
  let(:session_user) { FactoryBot.create(:session_user, groups: groups)}

  subject { described_class.new(session_user) }

  describe ".initialize" do
    it "has a logger instance variable" do
      expect(subject.instance_variable_get(:@logger)).to eq Rails.logger
    end

    it "has a product" do
      expect(subject.product).to eq "unknown"
    end

    it "has a user" do
      expect(subject.user).to eq session_user
    end
  end

  describe "#profile_view_allowed?" do
    it "returns true" do
      expect(subject.profile_view_allowed?).to eq false
    end
  end

  describe "#profile_edit_allowed?" do
    it "returns false" do
      expect(subject.profile_edit_allowed?).to eq false
    end
  end

  describe "#instance_edit_allowed?" do
    it "returns false" do
      expect(subject.instance_edit_allowed?).to eq false
    end
  end

  context "for undefined method" do
    it "return nil" do
      expect(subject.unknown_method).to eq nil
    end
  end

  describe "#copy_instance_tab" do
    context "for invalid arguments" do
      it "raises an error" do
        expect{subject.copy_instance_tab}.to raise_error(ArgumentError)
      end
    end

    context "for valid arguments" do
      let(:instance) { FactoryBot.create(:instance) }

      context "when standalone instance" do
        before { allow(instance).to receive(:standalone?).and_return(true) }

        context "and row_type is instance_as_part_of_concept_record" do
          let(:row_type) { "instance_as_part_of_concept_record" }
          it "returns tab_copy_to_new_reference" do
            expect(subject.copy_instance_tab(instance, row_type)).to eq "tab_copy_to_new_reference"
          end
        end

        context "when row_type is not defined" do
          it "returns nil" do
            expect(subject.copy_instance_tab(instance)).to eq nil
          end
        end
      end

      context "for other instance type" do
        before { allow(instance).to receive(:standalone?).and_return(false) }
        it "returns nil" do
          expect(subject.copy_instance_tab(instance)).to eq nil
        end
      end
    end
  end

  describe "#synonymy_tab" do
    let(:instance) { FactoryBot.create(:instance) }

    context "for invalid arguments" do
      it "raises an error" do
        expect{subject.synonymy_tab}.to raise_error(ArgumentError)
      end
    end

    context "when standalone instance" do
      it "returns tab_synonymy" do
        expect(subject.synonymy_tab(instance)).to eq "tab_synonymy"
      end
    end
  end

  describe "#unpublished_citation_tab" do
    let(:instance) { FactoryBot.create(:instance) }

    context "for invalid arguments" do
      it "raises an error" do
        expect{subject.unpublished_citation_tab}.to raise_error(ArgumentError)
      end
    end

    context "for valid argument" do
      it "returns tab_unpublished_citation" do
        expect(subject.unpublished_citation_tab(instance)).to eq "tab_unpublished_citation"
      end
    end
  end
end
