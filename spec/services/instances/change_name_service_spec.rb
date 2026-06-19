# frozen_string_literal: true

require "rails_helper"

describe Instances::ChangeNameService do
  let(:name_rank) { create(:name_rank) }
  let(:name_type) { create(:name_type) }
  let(:current_name) { create(:name, name_type:, name_rank:) }
  let(:draft_instance) { create(:instance, name: current_name, draft: true) }
  let(:username) { "test_editor" }

  subject(:service) do
    described_class.new(
      instance: draft_instance,
      new_name_id: new_name.id,
      username: username
    )
  end

  describe "#execute" do
    context "when the new name matches the current type and rank" do
      let(:new_name) { create(:name, name_type:, name_rank:) }

      it "changes the instance name in the database" do
        service.execute
        expect(draft_instance.reload.name_id).to eq(new_name.id)
      end

      it "records the user who made the change" do
        service.execute
        expect(draft_instance.reload.updated_by).to eq(username)
      end

      it "succeeds without errors" do
        service.execute
        expect(service.errors).to be_empty
      end
    end

    context "when the new name is already listed as a synonym" do
      let(:new_name) { create(:name, name_type:, name_rank:) }

      before do
        cites = build(:instance, name: new_name, reference: draft_instance.reference)
        cites.save(validate: false)
        syn = build(:instance, cited_by_id: draft_instance.id, cites_id: cites.id,
          name: new_name, reference: draft_instance.reference)
        syn.save(validate: false)
      end

      it "does not change the instance name" do
        expect { service.execute }.not_to change { draft_instance.reload.name_id }
      end

      it "reports an error" do
        service.execute
        expect(service.errors).not_to be_empty
      end
    end

    context "when the new name has a different type" do
      let(:new_name) { create(:name, name_type: create(:name_type), name_rank:) }

      it "does not change the instance name" do
        expect { service.execute }.not_to change { draft_instance.reload.name_id }
      end

      it "reports an error" do
        service.execute
        expect(service.errors).not_to be_empty
      end
    end

    context "when the new name has a different rank" do
      let(:new_name) { create(:name, name_type:, name_rank: create(:name_rank)) }

      it "does not change the instance name" do
        expect { service.execute }.not_to change { draft_instance.reload.name_id }
      end

      it "reports an error" do
        service.execute
        expect(service.errors).not_to be_empty
      end
    end

    context "when create_synonym is requested" do
      let(:new_name) { create(:name, name_type:, name_rank:) }
      let(:synonym_name) { create(:name, name_type:, name_rank:) }
      let(:synonym_instance_type) do
        create(:instance_type,
          relationship: true, primary_instance: false,
          deprecated: false, unsourced: false, misapplied: false)
      end
      let(:cites_instance) do
        create(:instance, name: synonym_name, reference: draft_instance.reference)
      end

      subject(:service) do
        described_class.new(
          instance: draft_instance,
          new_name_id: new_name.id,
          username: username,
          create_synonym: "yes",
          cites_id: cites_instance.id,
          synonym_instance_type_id: synonym_instance_type.id
        )
      end

      # accepted_concept? reaches for the live classification tree, which is not
      # set up in the test database.
      before { allow_any_instance_of(Instance).to receive(:accepted_concept?).and_return(false) }

      it "changes the instance name" do
        service.execute
        expect(draft_instance.reload.name_id).to eq(new_name.id)
      end

      it "creates one synonym instance cited by this instance" do
        expect { service.execute }
          .to change { Instance.where(cited_by_id: draft_instance.id).count }.by(1)
      end

      it "builds the synonym from the cites instance and chosen type" do
        service.execute
        synonym = Instance.find_by(cited_by_id: draft_instance.id, cites_id: cites_instance.id)
        expect(synonym).to be_present
        expect(synonym).to have_attributes(
          name_id: synonym_name.id,
          instance_type_id: synonym_instance_type.id,
          reference_id: draft_instance.reference_id
        )
      end

      it "succeeds without errors" do
        service.execute
        expect(service.errors).to be_empty
      end

      context "but the user selected no" do
        subject(:service) do
          described_class.new(
            instance: draft_instance,
            new_name_id: new_name.id,
            username: username,
            create_synonym: "no",
            cites_id: cites_instance.id,
            synonym_instance_type_id: synonym_instance_type.id
          )
        end

        it "changes the name without creating a synonym" do
          cites_instance # create the standalone instance before measuring
          expect { service.execute }
            .not_to change { Instance.where(cited_by_id: draft_instance.id).count }
          expect(draft_instance.reload.name_id).to eq(new_name.id)
        end
      end

      context "when the synonym is invalid" do
        # The cites instance shares the new name, so the synonym would be a
        # synonym of itself and fail validation.
        let(:cites_instance) do
          create(:instance, name: new_name, reference: draft_instance.reference)
        end

        it "rolls back the name change" do
          cites_instance
          expect { service.execute }.not_to change { draft_instance.reload.name_id }
        end

        it "does not create a synonym instance" do
          cites_instance
          expect { service.execute }.not_to change { Instance.count }
        end

        it "reports an error" do
          service.execute
          expect(service.errors).not_to be_empty
        end
      end
    end
  end
end
