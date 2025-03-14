require 'rails_helper'

RSpec.describe Ability, type: :model do
  describe "#profile_v2_viewer" do
    let(:session_user) { FactoryBot.create(:session_user) }

    subject { described_class.new(session_user) }

    before do
      allow(session_user).to receive(:with_role?).with('draft-profile-editor').and_return(false)
      allow(session_user).to receive(:with_role?).with('profile-editor').and_return(false)
    end

    xdescribe "#profile_v2_auth role" do
      context "for session_user with profile_v2" do
        before { allow(session_user).to receive(:profile_v2?).and_return(true) }
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

    describe "#draft_profile_editor role" do
      before do
        allow(session_user).to receive(:with_role?).with('draft-profile-editor').and_return(true)
      end

      it 'can manage profile_v2' do
        expect(subject.can?(:manage, :profile_v2)).to eq true
      end

      it 'can manage draft instances' do
        instance = FactoryBot.create(:instance, draft: true)
        expect(subject.can?(:manage_profile, instance)).to eq true
      end

      it 'cannot manage non-draft instances' do
        instance = FactoryBot.create(:instance, draft: false)
        expect(subject.can?(:manage_profile, instance)).to eq false
      end

      it 'can access authors' do
        expect(subject.can?('authors', :all)).to eq true
      end

      it 'can create and read authors' do
        expect(subject.can?(:create, Author)).to eq true
        expect(subject.can?(:read, Author)).to eq true
      end

      it 'can update authors with specific conditions' do
        author = FactoryBot.create(:author)
        allow(author).to receive(:referenced_in_any_instance?).and_return(false)
        allow(author).to receive(:no_other_authored_names?).and_return(true)
        expect(subject.can?(:update, author)).to eq true
      end

      it 'cannot update authors if conditions are not met' do
        author = FactoryBot.create(:author)
        allow(author).to receive(:referenced_in_any_instance?).and_return(false)
        allow(author).to receive(:no_other_authored_names?).and_return(false)
        expect(subject.can?(:update, author)).to eq false

        allow(author).to receive(:referenced_in_any_instance?).and_return(true)
        allow(author).to receive(:no_other_authored_names?).and_return(true)
        expect(subject.can?(:update, author)).to eq false

        allow(author).to receive(:referenced_in_any_instance?).and_return(true)
        allow(author).to receive(:no_other_authored_names?).and_return(false)
        expect(subject.can?(:update, author)).to eq false
      end

      it 'can create Profile::ProfileItem' do
        expect(subject.can?(:create, Profile::ProfileItem)).to eq true
      end

      it 'can manage draft Profile::ProfileItem' do
        profile_item = FactoryBot.create(:profile_item, is_draft: true)
        expect(subject.can?(:manage, profile_item)).to eq true
      end

      it 'cannot manage non-draft Profile::ProfileItem' do
        profile_item = FactoryBot.create(:profile_item, is_draft: false)
        expect(subject.can?(:manage, profile_item)).to eq false
      end

      it 'can manage draft Profile::ProfileItemReference' do
        profile_item = FactoryBot.create(:profile_item, is_draft: true)
        profile_item_reference = FactoryBot.create(:profile_item_reference, profile_item: profile_item)
        expect(subject.can?(:manage, profile_item_reference)).to eq true
      end

      it 'cannot manage non-draft Profile::ProfileItemReference' do
        profile_item = FactoryBot.create(:profile_item, is_draft: false)
        profile_item_reference = FactoryBot.create(:profile_item_reference, profile_item: profile_item)
        expect(subject.can?(:manage, profile_item_reference)).to eq false
      end

      it 'can manage draft Profile::ProfileText' do
        profile_item = FactoryBot.create(:profile_item, is_draft: true)
        profile_text = FactoryBot.create(:profile_text, profile_item: profile_item)
        expect(subject.can?(:manage, profile_text)).to eq true
      end

      it 'cannot manage non-draft Profile::ProfileText' do
        profile_item = FactoryBot.create(:profile_item, is_draft: false)
        profile_text = FactoryBot.create(:profile_text, profile_item: profile_item)
        expect(subject.can?(:manage, profile_text)).to eq false
      end

      it 'can manage draft Profile::ProfileItemAnnotation' do
        profile_item = FactoryBot.create(:profile_item, is_draft: true)
        profile_item_annotation = FactoryBot.create(:profile_item_annotation, profile_item: profile_item)
        expect(subject.can?(:manage, profile_item_annotation)).to eq true
      end

      it 'cannot manage non-draft Profile::ProfileItemAnnotation' do
        profile_item = FactoryBot.create(:profile_item, is_draft: false)
        profile_item_annotation = FactoryBot.create(:profile_item_annotation, profile_item: profile_item)
        expect(subject.can?(:manage, profile_item_annotation)).to eq false
      end

      it 'can create references' do
        expect(subject.can?(:create, Reference)).to eq true
      end

      it 'can update references with no instances' do
        reference = FactoryBot.create(:reference)
        allow(reference).to receive(:instances).and_return([])
        expect(subject.can?(:update, reference)).to eq true
      end

      it 'cannot update references with instances' do
        reference = FactoryBot.create(:reference)
        allow(reference).to receive(:instances).and_return([FactoryBot.create(:instance)])
        expect(subject.can?(:update, reference)).to eq false
      end

      it 'can access references actions' do
        expect(subject.can?("references", "new_row")).to eq true
        expect(subject.can?("references", "new")).to eq true
        expect(subject.can?("references", "typeahead_on_citation_for_parent")).to eq true
        expect(subject.can?("references", "typeahead_on_citation")).to eq true
        expect(subject.can?("references", "create")).to eq true
        expect(subject.can?("references", "tab_edit_1")).to eq true
        expect(subject.can?("references", "tab_edit_2")).to eq true
        expect(subject.can?("references", "tab_edit_3")).to eq true
        expect(subject.can?("references", "update")).to eq true
      end

      it 'can access references typeahead_on_citation' do
        expect(subject.can?("references", "typeahead_on_citation")).to eq true
      end

      it 'can access profile_items' do
        expect(subject.can?("profile_items", :all)).to eq true
      end

      it 'can access profile_item_annotations' do
        expect(subject.can?("profile_item_annotations", :all)).to eq true
      end

      it 'can access profile_item_references' do
        expect(subject.can?("profile_item_references", :all)).to eq true
      end

      it 'can access instances tab_details' do
        expect(subject.can?("instances", "tab_details")).to eq true
      end

      it 'can access instances tab_profile_v2' do
        expect(subject.can?("instances", "tab_profile_v2")).to eq true
      end

      it 'can access menu new' do
        expect(subject.can?("menu", "new")).to eq true
      end

    end

    describe "#profile_editor role" do
      before do
        allow(session_user).to receive(:with_role?).with('profile-editor').and_return(true)
      end

      it 'can manage profile_v2' do
        expect(subject.can?(:manage, :profile_v2)).to eq true
      end

      it 'can manage Profile::ProfileItem' do
        expect(subject.can?(:manage, Profile::ProfileItem)).to eq true
      end

      it 'can manage Profile::ProfileItemReference' do
        expect(subject.can?(:manage, Profile::ProfileItemReference)).to eq true
      end

      it 'can manage Profile::ProfileText' do
        expect(subject.can?(:manage, Profile::ProfileText)).to eq true
      end

      it 'can manage Profile::ProfileItemAnnotation' do
        expect(subject.can?(:manage, Profile::ProfileItemAnnotation)).to eq true
      end

      it 'can access references typeahead_on_citation' do
        expect(subject.can?("references", "typeahead_on_citation")).to eq true
      end

      it 'can access profile_items' do
        expect(subject.can?("profile_items", :all)).to eq true
      end

      it 'can access profile_item_annotations' do
        expect(subject.can?("profile_item_annotations", :all)).to eq true
      end

      it 'can access profile_item_references' do
        expect(subject.can?("profile_item_references", :all)).to eq true
      end

      it 'can access instances tab_details' do
        expect(subject.can?("instances", "tab_details")).to eq true
      end

      it 'can access instances tab_profile_v2' do
        expect(subject.can?("instances", "tab_profile_v2")).to eq true
      end
    end
  end
end
