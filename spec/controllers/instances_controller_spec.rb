# spec/controllers/instances_controller_spec.rb
require 'rails_helper'

RSpec.describe InstancesController, type: :controller do
  describe '#tabs_to_offer' do
    let(:user) { FactoryBot.create(:session_user) }
    let(:instance) { FactoryBot.create(:instance) }
    let(:profile_v2_context) { double('ProfileV2Context') }

    before do
      allow_any_instance_of(SessionUser).to receive(:profile_v2_context).and_return(profile_v2_context)
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
        allow(profile_v2_context).to receive(:unpublished_citation_tab).and_return('tab_unpublished_citation')
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
        allow(profile_v2_context).to receive(:copy_instance_tab).and_return(nil)
        allow(profile_v2_context).to receive(:unpublished_citation_tab).and_return(nil)
        allow(profile_v2_context).to receive(:synonymy_tab).and_return(nil)
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
end
