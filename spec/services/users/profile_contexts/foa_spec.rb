require "rails_helper"

RSpec.describe Users::ProfileContexts::Foa, type: :service do
  let(:groups) { ["foa"] }
  let(:session_user) { FactoryBot.create(:session_user, groups:) }

  subject { described_class.new(session_user) }

  describe ".initialize" do
    it "has a logger instance variable" do
      expect(subject.instance_variable_get(:@logger)).to eq Rails.logger
    end

    it "has a product" do
      expect(subject.product).to eq "FOA"
    end

    it "has a user" do
      expect(subject.user).to eq session_user
    end
  end

  context "for undefined method" do
    it "return nil" do
      expect(subject.unknown_method).to eq nil
    end
  end

  describe "#profile_view_allowed?" do
    before { allow(subject).to receive(:draft_instance_action_allowed?).and_return(true) }
    it "returns true" do
      expect(subject.profile_view_allowed?).to eq true
    end
  end

  describe "#profile_edit_allowed?" do
    before { allow(subject).to receive(:draft_instance_action_allowed?).and_return(true) }
    context "for foa group" do
      it "returns true" do
        expect(subject.profile_edit_allowed?).to eq true
      end
    end

    context "for non v2-profile-instance-edit group" do
      let(:groups) { ["nonfoa"] }
      it "returns false" do
        expect(subject.profile_edit_allowed?).to eq false
      end
    end
  end

  describe "#instance_edit_allowed?" do
    before { allow(subject).to receive(:draft_instance_action_allowed?).and_return(true) }
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

  describe "#draft_instance_action_allowed?" do
    it "returns false" do
      expect(subject.draft_instance_action_allowed?).to eq false
    end
    context "for foa-context-group" do
      let(:groups) { ["foa", "foa-context-group"] }
      it "returns true" do
        expect(subject.draft_instance_action_allowed?).to eq true
      end
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

      before { allow(subject).to receive(:draft_instance_action_allowed?).and_return(true) }

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

  describe "#synonymy_tab" do
    let(:instance) { FactoryBot.create(:instance) }

    before {allow(subject).to receive(:draft_instance_action_allowed?).and_return(true)}

    context "for invalid arguments" do
      it "raises an error" do
        expect{subject.synonymy_tab}.to raise_error(ArgumentError)
      end
    end

    context "when instance is a secondary reference" do
      before { allow(instance).to receive(:secondary_reference?).and_return(true) }

      context "and is a draft instance" do
        before { allow(instance).to receive(:draft).and_return(true) }
        it "returns tab_synonymy" do
          expect(subject.synonymy_tab(instance)).to eq "tab_synonymy_for_profile_v2"
        end
      end

      context "and is a non-draft instance" do
        before { allow(instance).to receive(:draft).and_return(false) }
        it "returns nil" do
          expect(subject.synonymy_tab(instance)).to eq nil
        end
      end
    end

    context "when instance is not a secondary reference" do
      before { allow(instance).to receive(:secondary_reference?).and_return(false) }
      it "returns nil" do
        expect(subject.synonymy_tab(instance)).to eq nil
      end
    end

    context "when draft_instance_action_allowed? is false" do
      before {allow(subject).to receive(:draft_instance_action_allowed?).and_return(false)}
      it "returns tab_synonymy from base class" do
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

    context "when instance is a secondary reference" do
      context "when draft_instance_action_allowed? is true" do
        before do
          allow(subject).to receive(:draft_instance_action_allowed?).and_return(true)
          allow(instance).to receive(:secondary_reference?).and_return(true)
        end

        context "and is a draft instance" do
          before { allow(instance).to receive(:draft).and_return(true) }
          it "returns tab_unpublished_citation_for_profile_v2" do
            expect(subject.unpublished_citation_tab(instance)).to eq "tab_unpublished_citation_for_profile_v2"
          end
        end

        context "and is a non-draft instance" do
          before { allow(instance).to receive(:draft).and_return(false) }
          it "returns nil" do
            expect(subject.unpublished_citation_tab(instance)).to eq nil
          end
        end
      end

      context "when draft_instance_action_allowed? is false" do
        before { allow(subject).to receive(:draft_instance_action_allowed?).and_return(false) }
        it "returns tab_unpublished_citation" do
          expect(subject.unpublished_citation_tab(instance)).to eq "tab_unpublished_citation"
        end
      end
    end

    context "when instance is not a secondary reference" do
      before { allow(instance).to receive(:secondary_reference?).and_return(false) }

      context "and draft_instance_action_allowed? is true" do
        before { allow(subject).to receive(:draft_instance_action_allowed?).and_return(true) }
        it "returns nil" do
          expect(subject.unpublished_citation_tab(instance)).to eq nil
        end
      end

      context "and draft_instance_action_allowed? is false" do
        before { allow(subject).to receive(:draft_instance_action_allowed?).and_return(false) }
        it "returns tab_unpublished_citation" do
          expect(subject.unpublished_citation_tab(instance)).to eq "tab_unpublished_citation"
        end
      end
    end
  end
end
