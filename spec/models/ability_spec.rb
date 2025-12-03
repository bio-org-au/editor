require 'rails_helper'

RSpec.describe Ability, type: :model do

  let(:session_user) { create(:session_user) }

  before do
    allow(session_user).to receive(:with_role?).with('draft-profile-editor').and_return(false)
    allow(session_user).to receive(:with_role?).with('draft-editor').and_return(false)
    allow(session_user).to receive(:with_role?).with('profile-editor').and_return(false)
    allow(session_user).to receive(:with_role?).with('profile-reference').and_return(false)
    allow(session_user).to receive(:with_role?).with('tree-builder').and_return(false)
    allow(session_user).to receive(:with_role?).with('tree-publisher').and_return(false)
    allow(session_user).to receive(:with_role?).with('name-index-editor').and_return(false)
    allow(session_user).to receive(:user_id).and_return(1)
    allow(session_user).to receive(:product_from_context).and_return(nil)
  end

  subject { described_class.new(session_user) }

  describe "#basic_auth_1" do
    it "allows setting include common cultivars" do
      expect(subject.can?("application", "set_include_common_cultivars")).to eq true
    end

    it "allows accessing authors tab_show_1" do
      expect(subject.can?("authors", "tab_show_1")).to eq true
    end

    it "allows accessing help" do
      expect(subject.can?("help", :all)).to eq true
    end

    it "allows accessing history" do
      expect(subject.can?("history", :all)).to eq true
    end

    it "allows accessing instance_types index" do
      expect(subject.can?("instance_types", "index")).to eq true
    end

    it "allows accessing instances tab_show_1" do
      expect(subject.can?("instances", "tab_show_1")).to eq true
    end

    it "allows updating reference id widgets" do
      expect(subject.can?("instances", "update_reference_id_widgets")).to eq true
    end

    it "allows accessing menu help" do
      expect(subject.can?("menu", "help")).to eq true
    end

    it "allows accessing menu user" do
      expect(subject.can?("menu", "user")).to eq true
    end

    it "allows accessing menu admin" do
      expect(subject.can?("menu", "admin")).to eq true
    end

    it "allows accessing admin index" do
      expect(subject.can?("admin", "index")).to eq true
    end

    it "allows setting product context" do
      expect(subject.can?("product_contexts/set_context", "create")).to eq true
    end
  end

  describe "#draft_profile_editor role" do
    let(:product) { create(:product, is_name_index: false) }

    before do
      allow(session_user).to receive(:with_role?).with('draft-profile-editor').and_return(true)
      allow(session_user).to receive(:product_from_context).and_return(product)
      allow(product).to receive(:is_name_index?).and_return(false)
    end

    it 'can manage profile_v2' do
      expect(subject.can?(:manage, :profile_v2)).to eq true
    end

    context 'when product_from_context is nil' do
      before do
        allow(session_user).to receive(:product_from_context).and_return(nil)
      end

      it 'can still manage profile_v2' do
        expect(subject.can?(:manage, :profile_v2)).to eq true
      end
    end

    context 'when product is a name index' do
      before do
        allow(product).to receive(:is_name_index?).and_return(true)
      end

      it 'cannot manage profile_v2' do
        expect(subject.can?(:manage, :profile_v2)).to eq false
      end
    end

    it 'can manage draft instances' do
      instance = create(:instance, draft: true)
      expect(subject.can?(:manage_profile, instance)).to eq true
    end

    it 'cannot manage non-draft instances' do
      instance = create(:instance, draft: false)
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
      author = create(:author)
      allow(author).to receive(:referenced_in_any_instance?).and_return(false)
      allow(author).to receive(:no_other_authored_names?).and_return(true)
      allow(author).to receive_message_chain(:names, :blank?).and_return(true)
      expect(subject.can?(:update, author)).to eq true
    end

    it 'cannot update authors if conditions are not met' do
      author = create(:author)
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
      profile_item = create(:profile_item, is_draft: true)
      expect(subject.can?(:manage, profile_item)).to eq true
    end

    it 'cannot manage non-draft Profile::ProfileItem' do
      profile_item = create(:profile_item, is_draft: false)
      expect(subject.can?(:manage, profile_item)).to eq false
    end

    it 'can manage draft Profile::ProfileItemReference' do
      profile_item = create(:profile_item, is_draft: true)
      profile_item_reference = create(:profile_item_reference, profile_item: profile_item)
      expect(subject.can?(:manage, profile_item_reference)).to eq true
    end

    it 'cannot manage non-draft Profile::ProfileItemReference' do
      profile_item = create(:profile_item, is_draft: false)
      profile_item_reference = create(:profile_item_reference, profile_item: profile_item)
      expect(subject.can?(:manage, profile_item_reference)).to eq false
    end

    it 'can manage draft Profile::ProfileText' do
      profile_item = create(:profile_item, is_draft: true)
      profile_text = create(:profile_text, profile_item: profile_item)
      expect(subject.can?(:manage, profile_text)).to eq true
    end

    it 'cannot manage non-draft Profile::ProfileText' do
      profile_item = create(:profile_item, is_draft: false)
      profile_text = create(:profile_text, profile_item: profile_item)
      expect(subject.can?(:manage, profile_text)).to eq false
    end

    it 'can manage draft Profile::ProfileItemAnnotation' do
      profile_item = create(:profile_item, is_draft: true)
      profile_item_annotation = create(:profile_item_annotation, profile_item: profile_item)
      expect(subject.can?(:manage, profile_item_annotation)).to eq true
    end

    it 'cannot manage non-draft Profile::ProfileItemAnnotation' do
      profile_item = create(:profile_item, is_draft: false)
      profile_item_annotation = create(:profile_item_annotation, profile_item: profile_item)
      expect(subject.can?(:manage, profile_item_annotation)).to eq false
    end

    it 'can create references' do
      expect(subject.can?(:create, Reference)).to eq true
    end

    context 'when updating references' do
      let(:reference) { create(:reference) }

      it 'cannot update references when no matching profile item reference exists' do
        allow(reference).to receive(:instances).and_return([])

        expect(subject.can?(:update, reference)).to eq false
      end

      context "with profile item reference" do
        let!(:product_item_config) { create(:product_item_config, product: product) }
        let!(:profile_item) { create(:profile_item, product_item_config: product_item_config) }
        let!(:profile_item_reference) { create(:profile_item_reference, profile_item: profile_item, reference: reference) }

        it 'can update references with no instances and matching profile item reference' do
          allow(reference).to receive(:instances).and_return([])

          expect(subject.can?(:update, reference)).to eq true
        end

        it 'cannot update references with instances even if profile item reference exists' do
          create(:instance, reference: reference)

          expect(subject.can?(:update, reference)).to eq false
        end
      end

      context 'when product_from_context is nil' do
        before do
          allow(session_user).to receive(:product_from_context).and_return(nil)
        end

        it 'can update references with no instances' do
          allow(reference).to receive(:instances).and_return([])
          expect(subject.can?(:update, reference)).to eq true
        end

        it 'cannot update references with instances' do
          allow(reference).to receive(:instances).and_return([create(:instance)])
          expect(subject.can?(:update, reference)).to eq false
        end
      end
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

  describe "#profile_reference role" do
    let(:product) { create(:product, is_name_index: false) }

    before do
      allow(session_user).to receive(:with_role?).with('profile-reference').and_return(true)
      allow(session_user).to receive(:product_from_context).and_return(product)
      allow(product).to receive(:is_name_index?).and_return(false)
    end

    context 'when product_from_context is nil' do
      before do
        allow(session_user).to receive(:product_from_context).and_return(nil)
      end

      it 'can still create and read authors' do
        expect(subject.can?(:create, Author)).to eq true
        expect(subject.can?(:read, Author)).to eq true
      end
    end

    context 'when product is a name index' do
      before do
        allow(product).to receive(:is_name_index?).and_return(true)
      end

      it 'cannot create authors' do
        expect(subject.can?(:create, Author)).to eq false
      end

      it 'cannot create references' do
        expect(subject.can?(:create, Reference)).to eq false
      end
    end

    it 'can access authors' do
      expect(subject.can?('authors', :all)).to eq true
    end

    it 'can create and read authors' do
      expect(subject.can?(:create, Author)).to eq true
      expect(subject.can?(:read, Author)).to eq true
    end

    it 'can update authors with specific conditions' do
      author = create(:author)
      allow(author).to receive(:referenced_in_any_instance?).and_return(false)
      allow(author).to receive(:no_other_authored_names?).and_return(true)
      allow(author).to receive_message_chain(:names, :blank?).and_return(true)
      expect(subject.can?(:update, author)).to eq true
    end

    it 'cannot update authors if conditions are not met' do
      author = create(:author)
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

    it 'can create references' do
      expect(subject.can?(:create, Reference)).to eq true
    end

    context 'when updating references' do
      let(:instance) { create(:instance) }
      let!(:reference) { create(:reference) }

      it 'cannot update references when no matching profile item reference exists' do
        allow(reference).to receive(:instances).and_return([])
        expect(subject.can?(:update, reference)).to eq false
      end

      context "with profile item reference" do
        let!(:product_item_config) { create(:product_item_config, product: product) }
        let!(:profile_item) { create(:profile_item, product_item_config: product_item_config) }
        let!(:profile_item_reference) { create(:profile_item_reference, profile_item: profile_item, reference: reference) }

        it 'can update references with no instances and matching profile item reference' do
          allow(reference).to receive(:instances).and_return([])

          expect(subject.can?(:update, reference)).to eq true
        end

        it 'cannot update references with instances even if profile item reference exists' do
          allow(reference).to receive(:instances).and_return([instance])

          expect(subject.can?(:update, reference)).to eq false
        end
      end

      context 'when product_from_context is nil' do
        before do
          allow(session_user).to receive(:product_from_context).and_return(nil)
        end

        it 'can update references with no instances' do
          allow(reference).to receive(:instances).and_return([])
          expect(subject.can?(:update, reference)).to eq true
        end

        it 'cannot update references with instances' do
          allow(reference).to receive(:instances).and_return([instance])
          expect(subject.can?(:update, reference)).to eq false
        end
      end
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

    it 'can access menu new' do
      expect(subject.can?("menu", "new")).to eq true
    end

    it 'cannot manage Profile::ProfileItem' do
      profile_item = create(:profile_item, is_draft: true)
      expect(subject.can?(:manage, profile_item)).to eq false
    end

    it 'cannot manage Profile::ProfileItemReference' do
      profile_item = create(:profile_item, is_draft: true)
      profile_item_reference = create(:profile_item_reference, profile_item: profile_item)
      expect(subject.can?(:manage, profile_item_reference)).to eq false
    end

    it 'cannot manage Profile::ProfileText' do
      profile_item = create(:profile_item, is_draft: true)
      profile_text = create(:profile_text, profile_item: profile_item)
      expect(subject.can?(:manage, profile_text)).to eq false
    end

    it 'cannot manage Profile::ProfileItemAnnotation' do
      profile_item = create(:profile_item, is_draft: true)
      profile_item_annotation = create(:profile_item_annotation, profile_item: profile_item)
      expect(subject.can?(:manage, profile_item_annotation)).to eq false
    end

    it 'cannot manage_profile on instances' do
      instance = create(:instance, draft: true)
      expect(subject.can?(:manage_profile, instance)).to eq false
    end

    it 'cannot access profile_items' do
      expect(subject.can?("profile_items", :all)).to eq false
    end

    it 'cannot access profile_item_annotations' do
      expect(subject.can?("profile_item_annotations", :all)).to eq false
    end

    it 'cannot access profile_item_references' do
      expect(subject.can?("profile_item_references", :all)).to eq false
    end

    it 'cannot access instances tab_profile_v2' do
      expect(subject.can?("instances", "tab_profile_v2")).to eq false
    end
  end

  describe "#draft_editor role" do
    let(:product) { create(:product, is_name_index: false) }

    before do
      allow(session_user).to receive(:with_role?).with('draft-editor').and_return(true)
      allow(session_user).to receive(:product_from_context).and_return(product)
      allow(product).to receive(:is_name_index?).and_return(false)
    end

    it 'can copy_as_draft_secondary_reference a published instance' do
      expect(subject.can?(:copy_as_draft_secondary_reference, Instance)).to eq true
    end

    context 'when product_from_context is nil' do
      before do
        allow(session_user).to receive(:product_from_context).and_return(nil)
      end

      it 'can still copy_as_draft_secondary_reference a published instance' do
        expect(subject.can?(:copy_as_draft_secondary_reference, Instance)).to eq true
      end
    end

    context 'when product is a name index' do
      before do
        allow(product).to receive(:is_name_index?).and_return(true)
      end

      it 'cannot copy_as_draft_secondary_reference' do
        expect(subject.can?(:copy_as_draft_secondary_reference, Instance)).to eq false
      end
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

    it 'can access references tab_new_instance' do
      expect(subject.can?("references", "tab_new_instance")).to eq true
    end

    it 'can access instances tab_synonymy_for_profile_v2' do
      expect(subject.can?("instances", "tab_synonymy_for_profile_v2")).to eq true
    end

    it 'can access instances typeahead_for_synonymy' do
      expect(subject.can?("instances", "typeahead_for_synonymy")).to eq true
    end

    it 'can access instances create_cites_and_cited_by' do
      expect(subject.can?("instances", "create_cites_and_cited_by")).to eq true
    end

    it 'can access instances create' do
      expect(subject.can?("instances", "create")).to eq true
    end

    it 'can access instances tab_edit' do
      expect(subject.can?("instances", "tab_edit")).to eq true
    end

    it 'can access instances tab_edit_profile_v2' do
      expect(subject.can?("instances", "tab_edit_profile_v2")).to eq true
    end

    it 'can access instances update' do
      expect(subject.can?("instances", "update")).to eq true
    end

    it 'can access instances destroy' do
      expect(subject.can?("instances", "destroy")).to eq true
    end

    it 'can access names tab_instances_profile_v2' do
      expect(subject.can?("names", "tab_instances_profile_v2")).to eq true
    end

    it "can create_with_product_reference an instance" do
      expect(subject.can?(:create_with_product_reference, Instance)).to eq true
    end

    it "allows copying as draft secondary reference" do
      instance = create(:instance, draft: false)
      expect(subject.can?(:copy_as_draft_secondary_reference, instance)).to eq true
    end

    context "for a relationship instance" do
      let(:instance) { create(:instance, draft: true) }

      let(:name_category) { create(:name_category, name: "cultivar") }
      let(:name_type) { create(:name_type, name: "cultivar", name_category: name_category) }
      let(:name) { create(:name, name_type: name_type) }
      let(:relationship_instance) { create(:instance, draft: false, name: name) }

      before do
        allow(relationship_instance).to receive(:relationship?).and_return(true)
        allow(relationship_instance).to receive(:this_is_cited_by).and_return(instance)
      end

      context "when product_from_context is set" do
        before do
          product = create(:product, name: "TEST_PRODUCT")
          products_collection = double('products_collection')
          allow(products_collection).to receive(:pluck).with(:name).and_return([product.name])
          allow(instance).to receive_message_chain(:reference, :products).and_return(products_collection)
          allow(session_user).to receive(:product_from_context).and_return(product)
        end

        it "can edit the relationship instance" do
          expect(subject.can?(:edit, relationship_instance)).to eq true
        end

        it "cannot edit the relationship instance if it's cited by an instance with different product" do
          other_product = create(:product, name: "other_product")
          other_products_collection = double('other_products_collection')
          allow(other_products_collection).to receive(:pluck).with(:name).and_return([other_product.name])
          allow(instance).to receive_message_chain(:reference, :products).and_return(other_products_collection)
          expect(subject.can?(:edit, relationship_instance)).to eq false
        end
      end

      context "when product_from_context is nil (uses product_from_roles)" do
        before do
          product = create(:product, name: "TEST_PRODUCT")
          products_collection = double('products_collection')
          allow(products_collection).to receive(:pluck).with(:name).and_return([product.name])
          allow(instance).to receive_message_chain(:reference, :products).and_return(products_collection)
          allow(session_user).to receive(:product_from_context).and_return(nil)
          allow(session_user).to receive(:product_from_roles).and_return(product)
        end

        it "can edit the relationship instance" do
          expect(subject.can?(:edit, relationship_instance)).to eq true
        end

        it "cannot edit the relationship instance if it's cited by an instance with different product" do
          other_product = create(:product, name: "other_product")
          other_products_collection = double('other_products_collection')
          allow(other_products_collection).to receive(:pluck).with(:name).and_return([other_product.name])
          allow(instance).to receive_message_chain(:reference, :products).and_return(other_products_collection)
          expect(subject.can?(:edit, relationship_instance)).to eq false
        end
      end

      it "cannot edit the relationship instance if not cited by a draft instance" do
        product = create(:product, name: "TEST_PRODUCT")
        products_collection = double('products_collection')
        allow(products_collection).to receive(:pluck).with(:name).and_return([product.name])
        allow(instance).to receive_message_chain(:reference, :products).and_return(products_collection)
        allow(session_user).to receive(:product_from_roles).and_return(product)
        allow(instance).to receive(:draft?).and_return(false)
        expect(subject.can?(:edit, relationship_instance)).to eq false
      end
    end

    context "when the instance is a draft" do
      let(:instance) { create(:instance, draft: true) }

      context "when product_from_context is set and matches instance product" do
        before do
          product = create(:product, name: "TEST_PRODUCT")
          products_collection = double('products_collection')
          allow(products_collection).to receive(:pluck).with(:name).and_return([product.name])
          allow(instance).to receive_message_chain(:reference, :products).and_return(products_collection)
          allow(session_user).to receive(:product_from_context).and_return(product)
        end

        it "allows destroying the instance" do
          expect(subject.can?(:destroy, instance)).to eq true
        end

        it "allows synonymy as draft secondary reference" do
          expect(subject.can?(:synonymy_as_draft_secondary_reference, instance)).to eq true
        end

        it "allows manage draft secondary reference" do
          expect(subject.can?(:manage_draft_secondary_reference, instance)).to eq true
        end

        it "allows unpublished citation as draft secondary reference" do
          expect(subject.can?(:unpublished_citation_as_draft_secondary_reference, instance)).to eq true
        end
      end

      context "when product_from_context is nil and product_from_roles matches instance product" do
        before do
          product = create(:product, name: "TEST_PRODUCT")
          products_collection = double('products_collection')
          allow(products_collection).to receive(:pluck).with(:name).and_return([product.name])
          allow(instance).to receive_message_chain(:reference, :products).and_return(products_collection)
          allow(session_user).to receive(:product_from_context).and_return(nil)
          allow(session_user).to receive(:product_from_roles).and_return(product)
        end

        it "allows destroying the instance" do
          expect(subject.can?(:destroy, instance)).to eq true
        end

        it "allows synonymy as draft secondary reference" do
          expect(subject.can?(:synonymy_as_draft_secondary_reference, instance)).to eq true
        end

        it "allows manage draft secondary reference" do
          expect(subject.can?(:manage_draft_secondary_reference, instance)).to eq true
        end

        it "allows unpublished citation as draft secondary reference" do
          expect(subject.can?(:unpublished_citation_as_draft_secondary_reference, instance)).to eq true
        end
      end

      context "when instance product reference is not the same as the user's product" do
        before do
          instance_product = create(:product, name: "INSTANCE_PRODUCT")
          user_product = create(:product, name: "USER_PRODUCT")
          products_collection = double('products_collection')
          allow(products_collection).to receive(:pluck).with(:name).and_return([instance_product.name])
          allow(instance).to receive_message_chain(:reference, :products).and_return(products_collection)
          allow(session_user).to receive(:product_from_context).and_return(nil)
          allow(session_user).to receive(:product_from_roles).and_return(user_product)
        end

        it "does not allows destroying the instance" do
          expect(subject.can?(:destroy, instance)).to eq false
        end

        it "does not allow synonymy as draft secondary reference" do
          expect(subject.can?(:synonymy_as_draft_secondary_reference, instance)).to eq false
        end

        it "does not allow manage draft secondary reference" do
          expect(subject.can?(:manage_draft_secondary_reference, instance)).to eq false
        end

        it "does not allow unpublished citation as draft secondary reference" do
          expect(subject.can?(:unpublished_citation_as_draft_secondary_reference, instance)).to eq false
        end
      end
    end

    context "when the instance is not a draft and cited by is also not a draft" do
      let(:instance) { double('instance', draft?: false, this_is_cited_by: double('citing_instance', draft?: false)) }

      it "does not allow updating the instance" do
        expect(subject.can?(:update, instance)).to eq false
      end

      it "does not allow destroying the instance" do
        expect(subject.can?(:destroy, instance)).to eq false
      end

      it "does not allow synonymy as draft secondary reference" do
        expect(subject.can?(:synonymy_as_draft_secondary_reference, instance)).to eq false
      end

      it "does not allow manage draft secondary reference" do
        expect(subject.can?(:manage_draft_secondary_reference, instance)).to eq false
      end

      it "does not allow unpublished citation as draft secondary reference" do
        expect(subject.can?(:unpublished_citation_as_draft_secondary_reference, instance)).to eq false
      end
    end
  end

  describe "#profile_editor role" do
    let(:product) { create(:product, is_name_index: false)}

    before do
      allow(session_user).to receive(:with_role?).with('profile-editor').and_return(true)
      allow(session_user).to receive(:product_from_context).and_return(product)
      allow(product).to receive(:is_name_index?).and_return(false)
    end

    it 'can manage profile_v2' do
      expect(subject.can?(:manage, :profile_v2)).to eq true
    end

    context 'when product_from_context is nil' do
      before do
        allow(session_user).to receive(:product_from_context).and_return(nil)
      end

      it 'can still manage profile_v2' do
        expect(subject.can?(:manage, :profile_v2)).to eq true
      end
    end

    context 'when product is a name index' do
      before do
        allow(product).to receive(:is_name_index?).and_return(true)
      end

      it 'cannot manage profile_v2' do
        expect(subject.can?(:manage, :profile_v2)).to eq false
      end
    end

    it 'can manage Profile::ProfileItem' do
      expect(subject.can?(:manage, Profile::ProfileItem)).to eq true
    end

    it "can manage published Profile::ProfileItem under a user's product" do
      user = create(:user, id: 1, user_name: session_user.username)

      product_role = create(:product_role, product: product)
      create(:user_product_role, user: user, product_role: product_role)

      product_item_config = create(:product_item_config, product: product)
      profile_item = create(:profile_item, product_item_config: product_item_config, is_draft: false)

      allow(profile_item).to receive(:published?).and_return(true)
      allow(session_user).to receive(:product_from_roles).and_return(product)

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
      # Create a user that matches the session_user's username for the user lookup to work
      user = create(:user, id: 1, user_name: session_user.username)
      product_role = create(:product_role, product: product)

      create(:user_product_role, user: user, product_role: product_role)

      product_item_config = create(:product_item_config, product: product)
      instance = create(:instance, draft: false)

      create(:profile_item, instance: instance, product_item_config: product_item_config, is_draft: false)

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

  describe "#name_index_editor role" do
    let(:product) { create(:product, is_name_index: true) }

    before do
      allow(session_user).to receive(:with_role?).with('name-index-editor').and_return(true)
      allow(session_user).to receive(:product_from_context).and_return(product)
      allow(product).to receive(:is_name_index?).and_return(true)
    end

    context "when managing resources" do
      it "allows managing Author" do
        expect(subject.can?(:manage, Author)).to eq true
      end

      it "allows creating, reading, and destroying Reference" do
        expect(subject.can?(:create, Reference)).to eq true
        expect(subject.can?(:read, Reference)).to eq true
        expect(subject.can?(:destroy, Reference)).to eq true
      end

      it "allows updating Reference" do
        reference = create(:reference)
        expect(subject.can?(:update, reference)).to eq true
      end

      it "allows creating, editing, updating, and destroying Instance" do
        expect(subject.can?(:create, Instance)).to eq true
        expect(subject.can?(:edit, Instance)).to eq true
        expect(subject.can?(:update, Instance)).to eq true
        expect(subject.can?(:destroy, Instance)).to eq true
      end
    end

    context 'when product_from_context is nil' do
      before do
        allow(session_user).to receive(:product_from_context).and_return(nil)
      end

      it 'can still manage Author' do
        expect(subject.can?(:manage, Author)).to eq true
      end

      it 'can still update Reference' do
        reference = create(:reference)
        expect(subject.can?(:update, reference)).to eq true
      end
    end

    context 'when product is not a name index' do
      before do
        allow(product).to receive(:is_name_index?).and_return(false)
      end

      it 'cannot manage Author' do
        expect(subject.can?(:manage, Author)).to eq false
      end

      it 'cannot update Reference' do
        reference = create(:reference)
        expect(subject.can?(:update, reference)).to eq false
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

  describe "#basic_auth_2" do
    it "allows accessing names rules" do
      expect(subject.can?("names", "rules")).to eq true
    end

    it "allows accessing names tab_details" do
      expect(subject.can?("names", "tab_details")).to eq true
    end

    it "allows accessing references tab_show_1" do
      expect(subject.can?("references", "tab_show_1")).to eq true
    end

    it "allows accessing search" do
      expect(subject.can?("search", :all)).to eq true
    end

    it "allows accessing new_search" do
      expect(subject.can?("new_search", :all)).to eq true
    end

    it "allows accessing services" do
      expect(subject.can?("services", :all)).to eq true
    end

    it "allows accessing sessions" do
      expect(subject.can?("sessions", :all)).to eq true
    end

    it "allows editing passwords" do
      expect(subject.can?("passwords", "edit")).to eq true
    end

    it "allows showing password form" do
      expect(subject.can?("passwords", "show_password_form")).to eq true
    end

    it "allows password changed notification" do
      expect(subject.can?("passwords", "password_changed")).to eq true
    end

    it "allows updating passwords" do
      expect(subject.can?("passwords", "update")).to eq true
    end
  end

  describe "#qa_auth role" do
    before do
      allow(session_user).to receive(:qa?).and_return(true)
    end

    it "allows all actions on de_duplicates" do
      expect(subject.can?("de_duplicates", :all)).to eq true
    end

    it "allows all actions on tree_versions" do
      expect(subject.can?("tree_versions", :all)).to eq true
    end

    it "allows all actions on tree_version_elements" do
      expect(subject.can?("tree_version_elements", :all)).to eq true
    end

    it "allows all actions on tree_elements" do
      expect(subject.can?("tree_elements", :all)).to eq true
    end

    it "allows all actions on mode" do
      expect(subject.can?("mode", :all)).to eq true
    end

    it "allows all actions on orgs" do
      expect(subject.can?("orgs", :all)).to eq true
    end

    it "allows accessing tree_versions form_to_publish" do
      expect(subject.can?("tree_versions", "form_to_publish")).to eq true
    end

    it "allows accessing tree_versions publish" do
      expect(subject.can?("tree_versions", "publish")).to eq true
    end

    it "allows publishing TreeVersion" do
      expect(subject.can?(:publish, TreeVersion)).to eq true
    end
  end

  describe "#admin_auth role" do
    before do
      allow(session_user).to receive(:admin?).and_return(true)
    end

    it "allows all actions on admin" do
      expect(subject.can?("admin", :all)).to eq true
    end

    it "allows accessing menu admin" do
      expect(subject.can?("menu", "admin")).to eq true
    end

    it "allows all actions on users" do
      expect(subject.can?("users", :all)).to eq true
    end

    it "allows all actions on user/product_roles" do
      expect(subject.can?("user/product_roles", :all)).to eq true
    end
  end

  describe "#reviewer_auth role" do
    before do
      allow(session_user).to receive(:reviewer?).and_return(true)
    end

    it "allows all actions on loader/name/review/comments" do
      expect(subject.can?("loader/name/review/comments", :all)).to eq true
    end

    it "allows all actions on loader/name/review/votes" do
      expect(subject.can?("loader/name/review/votes", :all)).to eq true
    end

    it "allows all actions on loader/name/review/vote/in_bulk" do
      expect(subject.can?("loader/name/review/vote/in_bulk", :all)).to eq true
    end

    it "allows switching on loader/batch/review/mode" do
      expect(subject.can?("loader/batch/review/mode", "switch_on")).to eq true
    end

    it "allows showing loader/names" do
      expect(subject.can?("loader/names", "show")).to eq true
    end

    it "allows accessing loader/names tab_details" do
      expect(subject.can?("loader/names", "tab_details")).to eq true
    end

    it "allows accessing loader/names tab_comment" do
      expect(subject.can?("loader/names", "tab_comment")).to eq true
    end

    it "allows accessing loader/names tab_vote" do
      expect(subject.can?("loader/names", "tab_vote")).to eq true
    end
  end

  describe "#batch_loader_auth role" do
    before do
      allow(session_user).to receive(:batch_loader?).and_return(true)
    end

    it "allows all actions on loader/batches" do
      expect(subject.can?("loader/batches", :all)).to eq true
    end

    it "allows all actions on loader/names" do
      expect(subject.can?("loader/names", :all)).to eq true
    end

    it "allows all actions on loader/name/matches" do
      expect(subject.can?("loader/name/matches", :all)).to eq true
    end

    it "allows all actions on loader/name/match/suggestions/for_intended_tree_parent" do
      expect(subject.can?("loader/name/match/suggestions/for_intended_tree_parent", :all)).to eq true
    end

    it "allows all actions on loader/batch/reviews" do
      expect(subject.can?("loader/batch/reviews", :all)).to eq true
    end

    it "allows all actions on loader/batch/reviewers" do
      expect(subject.can?("loader/batch/reviewers", :all)).to eq true
    end

    it "allows all actions on loader/batch/review/periods" do
      expect(subject.can?("loader/batch/review/periods", :all)).to eq true
    end

    it "allows all actions on loader/batch/bulk" do
      expect(subject.can?("loader/batch/bulk", :all)).to eq true
    end

    it "allows all actions on loader/batch/job_lock" do
      expect(subject.can?("loader/batch/job_lock", :all)).to eq true
    end

    it "allows accessing menu batch" do
      expect(subject.can?("menu", "batch")).to eq true
    end

    it "allows all actions on loader/name/review/comments" do
      expect(subject.can?("loader/name/review/comments", :all)).to eq true
    end
  end

  describe "#loader_2_tab_auth role" do
    before do
      allow(session_user).to receive(:loader_2_tab_loader?).and_return(true)
    end

    it "allows all actions on loader/instances-loader-2" do
      expect(subject.can?("loader/instances-loader-2", :all)).to eq true
    end
  end

  describe "#treebuilder_auth role" do
    before do
      allow(session_user).to receive(:treebuilder?).and_return(true)
    end

    it "allows placing classification" do
      expect(subject.can?("classification", "place")).to eq true
    end

    it "allows all actions on trees" do
      expect(subject.can?("trees", :all)).to eq true
    end

    it "allows all actions on workspace_values" do
      expect(subject.can?("workspace_values", :all)).to eq true
    end

    it "allows toggling trees/workspaces/current" do
      expect(subject.can?("trees/workspaces/current", "toggle")).to eq true
    end

    it "allows accessing names/typeaheads/for_workspace_parent_name" do
      expect(subject.can?("names/typeaheads/for_workspace_parent_name", :all)).to eq true
    end

    it "allows names_typeahead_for_workspace_parent on TreeVersion" do
      expect(subject.can?(:names_typeahead_for_workspace_parent, TreeVersion)).to eq true
    end

    it "allows accessing menu tree" do
      expect(subject.can?("menu", "tree")).to eq true
    end

    it "allows editing TreeVersion" do
      expect(subject.can?(:edit, TreeVersion)).to eq true
    end

    it "allows setting workspace on TreeVersion" do
      expect(subject.can?(:set_workspace, TreeVersion)).to eq true
    end

    it "allows accessing tree_versions form_to_publish" do
      expect(subject.can?("tree_versions", "form_to_publish")).to eq true
    end

    it "allows accessing tree_versions publish" do
      expect(subject.can?("tree_versions", "publish")).to eq true
    end

    it "allows publishing TreeVersion" do
      expect(subject.can?(:publish, TreeVersion)).to eq true
    end

    it "allows toggling draft on Tree" do
      expect(subject.can?(:toggle_draft, Tree)).to eq true
    end

    it "allows creating draft on Tree" do
      expect(subject.can?(:create_draft, Tree)).to eq true
    end

    it "allows accessing tree_versions edit_draft" do
      expect(subject.can?("tree_versions", "edit_draft")).to eq true
    end

    it "allows updating draft on Tree::DraftVersion" do
      expect(subject.can?(:update_draft, Tree::DraftVersion)).to eq true
    end

    it "allows accessing tree_versions update_draft" do
      expect(subject.can?("tree_versions", "update_draft")).to eq true
    end

    it "allows accessing instances tab_classification" do
      expect(subject.can?("instances", "tab_classification")).to eq true
    end

    it "allows place_name on all" do
      expect(subject.can?(:place_name, :all)).to eq true
    end

    it "allows accessing trees update_excluded" do
      expect(subject.can?("trees", "update_excluded")).to eq true
    end

    it "allows update_excluded on all" do
      expect(subject.can?(:update_excluded, :all)).to eq true
    end

    it "allows replace_placement on all" do
      expect(subject.can?(:replace_placement, :all)).to eq true
    end

    it "allows remove_name_placement on all" do
      expect(subject.can?(:remove_name_placement, :all)).to eq true
    end

    it "allows reports on TreeVersion" do
      expect(subject.can?(:reports, TreeVersion)).to eq true
    end

    it "allows show_cas on TreeVersion" do
      expect(subject.can?(:show_cas, TreeVersion)).to eq true
    end

    it "allows show_diff on TreeVersion" do
      expect(subject.can?(:show_diff, TreeVersion)).to eq true
    end

    it "allows show_valrep on TreeVersion" do
      expect(subject.can?(:show_valrep, TreeVersion)).to eq true
    end

    it "allows run_cas on TreeVersion" do
      expect(subject.can?(:run_cas, TreeVersion)).to eq true
    end

    it "allows update_synonymy_by_instance on TreeVersion" do
      expect(subject.can?(:update_synonymy_by_instance, TreeVersion)).to eq true
    end

    it "allows run_diff on TreeVersion" do
      expect(subject.can?(:run_diff, TreeVersion)).to eq true
    end

    it "allows run_valrep on TreeVersion" do
      expect(subject.can?(:run_valrep, TreeVersion)).to eq true
    end

    it "allows update_distribution on TreeVersion" do
      expect(subject.can?(:update_distribution, TreeVersion)).to eq true
    end

    it "allows update_comment on TreeVersion" do
      expect(subject.can?(:update_comment, TreeVersion)).to eq true
    end

    it "allows update_tree_parent on TreeVersion" do
      expect(subject.can?(:update_tree_parent, TreeVersion)).to eq true
    end

    it "allows accessing tree/elements update_profile" do
      expect(subject.can?("tree/elements", "update_profile")).to eq true
    end
  end

end

