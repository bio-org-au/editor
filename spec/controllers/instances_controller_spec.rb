# spec/controllers/instances_controller_spec.rb
require 'rails_helper'

RSpec.describe InstancesController, type: :controller do
  describe '#tabs_to_offer' do
    let(:user) { FactoryBot.create(:session_user) }
    let(:instance) { FactoryBot.create(:instance) }

    before do
      allow(controller).to receive(:params).and_return({})
      allow(controller).to receive(:can?).and_return(true)
      controller.instance_variable_set(:@current_user, user)
    end

    context 'when instance is standalone' do
      before do
        allow(instance).to receive(:standalone?).and_return(true)
        allow(instance).to receive(:standalone?).and_return(true)
        allow(instance).to receive(:profile?).and_return(true)
        allow(instance).to receive(:show_taxo?).and_return(true)
        controller.instance_variable_set(:@instance, instance)
      end

      it 'includes specific tabs for standalone instances' do
        tabs = controller.send(:tabs_to_offer)
        expect(tabs).to include("tab_show_1", "tab_edit", "tab_edit_notes")
        expect(tabs).to include("tab_unpublished_citation", "tab_synonymy", "tab_classification")
        expect(tabs).to include("tab_profile_details", "tab_edit_profile", "tab_profile_v2", "tab_comments", "tab_synonymy")
      end

      it "includes 'tab_copy_to_new_reference' when row-type is 'instance_as_part_of_concept_record'" do
        allow(controller).to receive(:params).and_return({ "row-type" => "instance_as_part_of_concept_record" })
        tabs = controller.send(:tabs_to_offer)
        expect(tabs).to include("tab_copy_to_new_reference")
      end

      it "includes 'tab_synonymy_for_profile_v2' when instance is draft and secondary reference instance" do
        allow(instance).to receive(:draft?).and_return(true)
        allow(instance).to receive(:secondary_reference?).and_return(true)
        tabs = controller.send(:tabs_to_offer)
        expect(tabs).to include("tab_synonymy_for_profile_v2")
      end

      context 'when instance has a profile' do
        before do
          allow(instance).to receive(:profile?).and_return(true)
          allow(instance).to receive(:show_taxo?).and_return(true)
        end

        it 'includes profile related tabs' do
          expect(controller.send(:tabs_to_offer)).to include('tab_profile_details', 'tab_edit_profile')
        end
      end

      context "and the row-type params is 'instance_as_part_of_concept_record'" do
        before do
          allow(controller).to receive(:params).and_return({ "row-type" => "instance_as_part_of_concept_record" })
        end

        it "includes 'tab_copy_to_new_reference'" do
          tabs = controller.send(:tabs_to_offer)
          expect(tabs).to include("tab_copy_to_new_reference")
        end

        context "when the instance is non-draft" do
          before do
            allow(instance).to receive(:draft?).and_return(false)
          end

          it "includes 'tab_copy_to_new_profile_v2'" do
            tabs = controller.send(:tabs_to_offer)
            expect(tabs).to include("tab_copy_to_new_profile_v2")
          end
        end
      end
    end

    context 'when batch loader is aware and user has permissions' do
      before do
        allow(instance).to receive(:standalone?).and_return(true)
        allow(controller).to receive(:can?).with('loader/names', 'update').and_return(true)
        allow(controller).to receive(:offer_loader_tab?).and_return(true)
        allow(Rails.configuration).to receive(:try).with('batch_loader_aware').and_return(true)
        controller.instance_variable_set(:@instance, instance)
      end

      it 'includes batch loader tabs' do
        expect(controller.send(:tabs_to_offer)).to include('tab_batch_loader', 'tab_batch_loader_2')
      end
    end

    context 'when instance is not standalone' do
      before do
        allow(instance).to receive(:standalone?).and_return(false)
        controller.instance_variable_set(:@instance, instance)
      end

      it "does not include tabs specific to standalone instances" do
        tabs = controller.send(:tabs_to_offer)
        expect(tabs).not_to include("tab_synonymy", "tab_synonymy_for_profile_v2", "tab_classification", "tab_profile_details", "tab_edit_profile", "tab_profile_v2")
      end
    end
  end

  describe "GET #typeahead_for_product_item_config" do
    let(:session_user) { FactoryBot.create(:session_user, groups: ['login']) }
    let(:user) { FactoryBot.create(:user) }
    let(:instance) { FactoryBot.create(:instance) }
    let(:mock_typeahead_service) { double("Instance::AsTypeahead::ForProductItemConfig") }
    let(:mock_instances) { [instance] }
    let!(:profile_item) { instance_double("Profile::ProfileItem", id: 1, product_item_config_id: "1") }
    let(:params) { { instance_id: instance.id, term: "test", product_item_config_id: profile_item.product_item_config_id} }

    subject { get :typeahead_for_product_item_config, params: params }

    before do
      emulate_user_login(session_user)

      allow(Instance::AsTypeahead::ForProductItemConfig).to receive(:new)
        .with(product_item_config_id: params[:product_item_config_id], term: params[:term])
        .and_return(mock_typeahead_service)

      allow(mock_typeahead_service).to receive(:instances).and_return(mock_instances)
      allow(controller).to receive(:can?).with("instances", "typeahead_for_product_item_config").and_return(true)
      allow(controller).to receive(:authorise).and_return(true)
    end

    it "returns a successful response" do
      subject
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST #copy_for_profile_v2" do
    let(:session_user) { FactoryBot.create(:session_user, groups: ['login']) }
    let(:instance) { FactoryBot.create(:instance) }
    let(:mocked_instance) { instance_double("Instance", id: 1) }
    let(:params) do
      {
        id: instance.id,
        instance: {
          copy_profile_items: "1",
          multiple_primary_override: "0",
          duplicate_instance_override: "1"
        }
      }
    end

    before do
      emulate_user_login(session_user)
      allow(controller).to receive(:can?).with("instances", "copy_for_profile_v2").and_return(true)
      allow(controller).to receive(:authorise).and_return(true)
      allow_any_instance_of(Instance::AsCopier).to receive(:copy_with_product_reference).and_return(mocked_instance)
    end

    context 'when the copy is successful' do
      it 'copies the instance with product reference' do
        post :copy_for_profile_v2, params: params, xhr: true
        expect(assigns(:instance)).to eq(mocked_instance)
      end

      it 'sets the success message' do
        post :copy_for_profile_v2, params: params, xhr: true
        expect(assigns(:message)).to eq("Instance was copied")
      end

      it 'renders the success template' do
        post :copy_for_profile_v2, params: params, xhr: true
        expect(response).to render_template("instances/copy_standalone/success")
      end
    end

    context 'when an error occurs' do
      before do
        allow_any_instance_of(Instance::AsCopier).to receive(:copy_with_product_reference).and_raise(StandardError, "Something went wrong")
      end

      it 'handles the error and renders the error template' do
        post :copy_for_profile_v2, params: params, xhr: true
        expect(assigns(:message)).to eq(["Something went wrong"])
        expect(response).to render_template("instances/copy_standalone/error")
      end
    end
  end
end
