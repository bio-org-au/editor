require 'rails_helper'

RSpec.describe Ability, type: :model do

  let(:session_user) { FactoryBot.create(:session_user) }

  before do
    allow(session_user).to receive(:with_role?).with('draft-profile-editor').and_return(false)
    allow(session_user).to receive(:with_role?).with('draft-editor').and_return(false)
    allow(session_user).to receive(:with_role?).with('profile-editor').and_return(false)
  end

  subject { described_class.new(session_user) }

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
      allow(author).to receive_message_chain(:names, :blank?).and_return(true)
      expect(subject.can?(:update, author)).to eq true
    end

    it 'cannot update authors if conditions are not met' do
      author = FactoryBot.create(:author)
      allow(author).to receive(:referenced_in_any_instance?).and_return(false)
      allow(author).to receive(:no_other_authored_names?).and_return(false)
      allow(author).to receive_message_chain(:names, :blank?).and_return(true)
      expect(subject.can?(:update, author)).to eq false

      allow(author).to receive(:referenced_in_any_instance?).and_return(true)
      allow(author).to receive(:no_other_authored_names?).and_return(true)
      allow(author).to receive_message_chain(:names, :blank?).and_return(true)
      expect(subject.can?(:update, author)).to eq false

      allow(author).to receive(:referenced_in_any_instance?).and_return(true)
      allow(author).to receive(:no_other_authored_names?).and_return(false)
      allow(author).to receive_message_chain(:names, :blank?).and_return(true)
      expect(subject.can?(:update, author)).to eq false

      allow(author).to receive(:referenced_in_any_instance?).and_return(true)
      allow(author).to receive(:no_other_authored_names?).and_return(true)
      allow(author).to receive_message_chain(:names, :blank?).and_return(false)
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

    it 'can access instances typeahead_for_product_item_config' do
      expect(subject.can?("instances", "typeahead_for_product_item_config")).to eq true
    end

    it 'can access menu new' do
      expect(subject.can?("menu", "new")).to eq true
    end

  end

  describe "#draft_editor role" do
    before do
      allow(session_user).to receive(:with_role?).with('draft-editor').and_return(true)
    end

    it 'can copy_as_draft_secondary_reference a published instance' do
      expect(subject.can?(:copy_as_draft_secondary_reference, Instance)).to eq true
    end

    it 'can access instances tab_copy_to_new_profile_v2' do
      expect(subject.can?("instances", "tab_copy_to_new_profile_v2")).to eq true
    end

    it 'can access instances copy_for_profile_v2' do
      expect(subject.can?("instances", "copy_for_profile_v2")).to eq true
    end

    it 'can access instances create_cited_by' do
      expect(subject.can?("instances", "create_cited_by")).to eq true
    end

    it 'can access instances tab_unpublished_citation_for_profile_v2' do
      expect(subject.can?("instances", "tab_unpublished_citation_for_profile_v2")).to eq true
    end

    it 'can access names/typeaheads/for_unpub_cit index' do
      expect(subject.can?("names/typeaheads/for_unpub_cit", "index")).to eq true
    end

    it "allows copying as draft secondary reference" do
      instance = FactoryBot.create(:instance, draft: false)
      expect(subject.can?(:copy_as_draft_secondary_reference, instance)).to eq true
    end

    context "for a relationship instance" do
      let(:instance) { FactoryBot.create(:instance, draft: true) }

      let(:name_category) { FactoryBot.create(:name_category, name: "cultivar") }
      let(:name_type) { FactoryBot.create(:name_type, name: "cultivar", name_category: name_category) }
      let(:name) { FactoryBot.create(:name, name_type: name_type) }
      let(:relationship_instance) { FactoryBot.create(:instance, draft: false, name: name) }

      before do
        product = FactoryBot.create(:product)
        allow(instance).to receive_message_chain(:reference, :products).and_return([product])
        allow(session_user).to receive(:product_from_roles).and_return(product)
        allow(relationship_instance).to receive(:relationship?).and_return(true)
        allow(relationship_instance).to receive(:this_is_cited_by).and_return(instance)
      end

      it "can edit the relationship instance" do
        expect(subject.can?(:edit, relationship_instance)).to eq true
      end

      it "cannot edit the relationship instance if not cited by a draft instance" do
        allow(instance).to receive(:draft?).and_return(false)
        expect(subject.can?(:edit, relationship_instance)).to eq false
      end

      it "cannot edit the relationship instance if it's cited by an instance with different product" do
        other_product = FactoryBot.create(:product, name: "other_product")
        allow(instance).to receive_message_chain(:reference, :products).and_return([other_product])
        expect(subject.can?(:edit, relationship_instance)).to eq false
      end
    end

    context "when the instance is a draft" do
      let(:instance) { FactoryBot.create(:instance, draft: true) }

      context "when instance product reference is the same as the user's product" do
        before do
          product = FactoryBot.create(:product)
          allow(instance).to receive_message_chain(:reference, :products).and_return([product])
          allow(session_user).to receive(:product_from_roles).and_return(product)
        end

        it "allows destroying the instance" do
          expect(subject.can?(:destroy, instance)).to eq true
        end

        it "allows synonymy as draft secondary reference" do
          expect(subject.can?(:synonymy_as_draft_secondary_reference, instance)).to eq true
        end
      end

      context "when instance product reference is not the same as the user's product" do
        it "does not allows destroying the instance" do
          expect(subject.can?(:destroy, instance)).to eq false
        end

        it "does not allow synonymy as draft secondary reference" do
          allow(instance).to receive(:reference).and_return(FactoryBot.create(:reference))
          allow(session_user).to receive(:product_from_roles).and_return(FactoryBot.create(:product))
          expect(subject.can?(:synonymy_as_draft_secondary_reference, instance)).to eq false
        end
      end
    end

    context "when the instance is not a draft" do
      let(:instance) { FactoryBot.create(:instance, draft: false) }

      it "does not allow updating the instance" do
        expect(subject.can?(:update, instance)).to eq false
      end

      it "does not allow destroying the instance" do
        expect(subject.can?(:destroy, instance)).to eq false
      end

      it "does not allow synonymy as draft secondary reference" do
        expect(subject.can?(:synonymy_as_draft_secondary_reference, instance)).to eq false
      end
    end
  end

  describe "#profile_editor role" do
    let(:product) { create(:product)}

    before do
      allow(session_user).to receive(:with_role?).with('profile-editor').and_return(true)
    end

    it 'can manage profile_v2' do
      expect(subject.can?(:manage, :profile_v2)).to eq true
    end

    it 'can manage Profile::ProfileItem' do
      expect(subject.can?(:manage, Profile::ProfileItem)).to eq true
    end

    it "can manage published Profile::ProfileItem under a user's product" do
      profile_item = create(:profile_item)
      allow(profile_item).to receive(:published?).and_return(true)
      allow(session_user).to receive(:product_from_roles).and_return(product)
      allow(profile_item).to receive(:product_item_config).and_return(double("ProductItemConfig", product_id: product.id))
      expect(subject.can?(:manage, profile_item)).to eq true
    end

    it "cannot manage draft Profile::ProfileItem" do
      profile_item = create(:profile_item, is_draft: true)
      expect(subject.can?(:manage, profile_item)).to eq false
    end

    it 'can manage Profile::ProfileText' do
      expect(subject.can?(:manage, Profile::ProfileText)).to eq true
    end

    it "can create_version Profile::ProfileItem if it is not draft" do
      profile_item = create(:profile_item, is_draft: false)
      expect(subject.can?(:create_version, profile_item)).to eq true
    end

    it "cannot create_version Profile::ProfileItem if it is a draft" do
      profile_item = create(:profile_item, is_draft: true)
      expect(subject.can?(:create_version, profile_item)).to eq false
    end

    it "can publish Profile::ProfileItem if it is a draft version" do
      profile_item = create(:profile_item, is_draft: true)
      allow(profile_item).to receive(:draft_version?).and_return(true)
      expect(subject.can?(:publish, profile_item)).to eq true
    end

    it "cannot publish Profile::ProfileItem if it is not a draft version" do
      profile_item = create(:profile_item, is_draft: false)
      allow(profile_item).to receive(:draft_version?).and_return(false)
      expect(subject.can?(:publish, profile_item)).to eq false
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

    it "can manage_profile on instance if not draft and has profile items for product" do
      instance = create(:instance, draft: false)
      allow(instance).to receive_message_chain(:profile_items, :by_product).and_return([double("Product")])
      expect(subject.can?(:manage_profile, instance)).to eq true
    end

    it "cannot manage_profile on draft Instance" do
      instance = double(draft?: true)
      expect(subject.can?(:manage_profile, instance)).to eq false
    end

    it "cannot :manage_profile on Instance with no profile items for product" do
      instance = double(draft?: false, profile_items: double('profile_items', by_product: []))
      expect(subject.can?(:manage_profile, instance)).to eq false
    end
  end

  describe "#edit_auth role" do
    before do
      allow(session_user).to receive(:edit?).and_return(true)
    end

    context "when managing resources" do
      it "allows managing Author" do
        expect(subject.can?(:manage, Author)).to eq true
      end

      it "allows managing Reference" do
        expect(subject.can?(:manage, Reference)).to eq true
      end

      it "allows create Instance" do
        expect(subject.can?(:create, Instance)).to eq true
      end
    end

    context "when accessing specific actions" do
      it "allows all actions on authors" do
        expect(subject.can?("authors", :all)).to eq true
      end

      it "allows all actions on comments" do
        expect(subject.can?("comments", :all)).to eq true
      end

      it "allows all actions on instances" do
        expect(subject.can?("instances", :all)).to eq true
      end

      it "allows copying standalone instances" do
        expect(subject.can?("instances", "copy_standalone")).to eq true
      end

      it "allows all actions on instance notes" do
        expect(subject.can?("instance_notes", :all)).to eq true
      end

      it "allows accessing the 'new' menu" do
        expect(subject.can?("menu", "new")).to eq true
      end

      it "allows all actions on name tag names" do
        expect(subject.can?("name_tag_names", :all)).to eq true
      end

      it "allows all actions on names" do
        expect(subject.can?("names", :all)).to eq true
      end

      it "allows all actions on name deletions" do
        expect(subject.can?("names_deletes", :all)).to eq true
      end

      it "allows all actions on references" do
        expect(subject.can?("references", :all)).to eq true
      end

      it "allows all actions on unpublished citation typeaheads" do
        expect(subject.can?("names/typeaheads/for_unpub_cit", :all)).to eq true
      end

      it "allows switching off batch review mode" do
        expect(subject.can?("loader/batch/review/mode", "switch_off")).to eq true
      end
    end
  end
end
