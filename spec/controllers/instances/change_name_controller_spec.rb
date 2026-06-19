# frozen_string_literal: true

require "rails_helper"

RSpec.describe Instances::ChangeNameController, type: :controller do
  let(:session_user) { FactoryBot.create(:session_user, groups: ["login"]) }
  let(:name_type) { FactoryBot.create(:name_type) }
  let(:name_rank) { FactoryBot.create(:name_rank) }
  let(:current_name) { FactoryBot.create(:name, name_type:, name_rank:) }
  let(:instance) { FactoryBot.create(:instance, name: current_name, draft: true) }

  before do
    emulate_user_login(session_user)
    allow(controller).to receive(:can?).with("instances/change_name", "update").and_return(true)
    allow(controller).to receive(:can?).with("instances/change_name", "typeahead").and_return(true)
    allow(controller).to receive(:authorise).and_return(true)
  end

  describe "PATCH #update" do
    context "when no name is selected" do
      it "returns an error response without changing the name" do
        expect {
          patch :update, params: {instance_id: instance.id, instance: {name_id: ""}}, xhr: true
        }.not_to change { instance.reload.name_id }

        expect(response).to render_template("instances/change_name_error")
        expect(response).to have_http_status(:unprocessable_content)
      end
    end

    context "when the new name has the same type and rank" do
      let(:new_name) { FactoryBot.create(:name, name_type:, name_rank:) }

      it "updates the instance name and renders the success template" do
        patch :update, params: {instance_id: instance.id, instance: {name_id: new_name.id.to_s}}, xhr: true

        expect(instance.reload.name_id).to eq(new_name.id)
        expect(response).to render_template("instances/change_name")
      end
    end

    context "when the new name has a different type or rank" do
      let(:new_name) { FactoryBot.create(:name) }

      it "returns an error response without changing the name" do
        expect {
          patch :update, params: {instance_id: instance.id, instance: {name_id: new_name.id.to_s}}, xhr: true
        }.not_to change { instance.reload.name_id }

        expect(response).to render_template("instances/change_name_error")
        expect(response).to have_http_status(:unprocessable_content)
      end
    end

    context "when adding the name as a synonym" do
      let(:new_name) { FactoryBot.create(:name, name_type:, name_rank:) }
      let(:synonym_name) { FactoryBot.create(:name, name_type:, name_rank:) }
      let(:synonym_instance_type) do
        FactoryBot.create(:instance_type,
          relationship: true, primary_instance: false,
          deprecated: false, unsourced: false, misapplied: false)
      end
      let(:cites_instance) do
        FactoryBot.create(:instance, name: synonym_name, reference: instance.reference)
      end

      before { allow_any_instance_of(Instance).to receive(:accepted_concept?).and_return(false) }

      it "changes the name and creates the synonym instance" do
        expect {
          patch :update, params: {
            instance_id: instance.id,
            instance: {
              name_id: new_name.id.to_s,
              create_synonym: "yes",
              cites_id: cites_instance.id.to_s,
              synonym_instance_type_id: synonym_instance_type.id.to_s
            }
          }, xhr: true
        }.to change { Instance.where(cited_by_id: instance.id).count }.by(1)

        expect(instance.reload.name_id).to eq(new_name.id)
        expect(response).to render_template("instances/change_name")
      end

      context "when the instance or type is missing" do
        it "returns an error without changing the name" do
          expect {
            patch :update, params: {
              instance_id: instance.id,
              instance: {name_id: new_name.id.to_s, create_synonym: "yes"}
            }, xhr: true
          }.not_to change { instance.reload.name_id }

          expect(response).to render_template("instances/change_name_error")
          expect(response).to have_http_status(:unprocessable_content)
        end
      end
    end

    context "when the selected name is already a synonym of the instance" do
      let(:synonym_name) { FactoryBot.create(:name, name_type:, name_rank:) }

      before do
        cites = build(:instance, name: synonym_name, reference: instance.reference)
        cites.save(validate: false)
        syn = build(:instance, cited_by_id: instance.id, cites_id: cites.id,
          name: synonym_name, reference: instance.reference)
        syn.save(validate: false)
      end

      it "returns an error response without changing the name" do
        expect {
          patch :update, params: {instance_id: instance.id, instance: {name_id: synonym_name.id.to_s}}, xhr: true
        }.not_to change { instance.reload.name_id }

        expect(response).to render_template("instances/change_name_error")
        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end

  describe "GET #typeahead" do
    def result_ids
      JSON.parse(response.body).map { |r| r["id"] }
    end

    context "when searching with a matching term" do
      let(:matching_name) { FactoryBot.create(:name, name_type:, name_rank:, full_name: "Acacia dealbata") }

      before { matching_name }

      it "returns names with the same type and rank" do
        get :typeahead, params: {instance_id: instance.id, term: "Acacia"}
        expect(result_ids).to include(matching_name.id)
      end

      it "excludes names with a different rank" do
        other_rank_name = FactoryBot.create(:name, name_type:, name_rank: FactoryBot.create(:name_rank), full_name: "Acacia aneura")
        get :typeahead, params: {instance_id: instance.id, term: "Acacia"}
        expect(result_ids).not_to include(other_rank_name.id)
      end

      it "excludes the instance's current name" do
        # current_name has full_name "Sample Full name" — create another same-type name to confirm
        # only the current name is excluded, not all matches
        other_name = FactoryBot.create(:name, name_type:, name_rank:, full_name: "Sample Other name")
        get :typeahead, params: {instance_id: instance.id, term: "Sample"}
        expect(result_ids).not_to include(current_name.id)
        expect(result_ids).to include(other_name.id)
      end
    end

    context "when the term is blank" do
      it "returns an empty array" do
        get :typeahead, params: {instance_id: instance.id, term: ""}
        expect(JSON.parse(response.body)).to eq([])
      end
    end
  end
end
