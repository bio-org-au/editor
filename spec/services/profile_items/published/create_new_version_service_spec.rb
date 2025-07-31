require 'rails_helper'

RSpec.describe ProfileItems::Published::CreateNewVersionService, type: :service do
  let(:instance) { create(:instance) }
  let(:user) { create(:user) }
  let(:product_item_config) { create(:product_item_config) }
  let(:profile_item) { create(:profile_item, instance: instance, product_item_config: product_item_config, is_draft: false) }
  let!(:profile_text) { create(:profile_text, profile_item: profile_item) }
  let!(:profile_item_annotation) { create(:profile_item_annotation, profile_item: profile_item) }
  let!(:profile_item_reference) { create(:profile_item_reference, profile_item: profile_item) }

  subject do
    described_class.new(
      instance: instance,
      user: user,
      profile_item: profile_item,
      params: {}
    )
  end

  describe "#execute" do
    context "when profile item is published and no draft exists" do
      it "creates a new draft version with copied associations" do
        expect { subject.execute }.to change { Profile::ProfileItem.where(is_draft: true).count }.by(1)

        new_draft = Profile::ProfileItem.where(is_draft: true).last
        expect(new_draft.profile_text).to be_present
        expect(new_draft.profile_item_annotation).to be_present
        expect(new_draft.profile_item_references.count).to eq(1)
        expect(new_draft.profile_text.value_md).to eq(profile_text.value_md)
        expect(new_draft.profile_item_annotation.value).to eq(profile_item_annotation.value)
        expect(new_draft.profile_item_references.first.reference_id).to eq(profile_item_reference.reference_id)
      end

      context "when there are errors copying the profile item" do
        before do
          errors = ActiveModel::Errors.new(profile_item)
          errors.add(:base, "An error")
          allow_any_instance_of(Profile::ProfileItem).to receive(:save).and_return(errors)
          allow_any_instance_of(Profile::ProfileItem).to receive(:errors).and_return(errors)
        end

        it "rolls back the transaction and returns errors" do
          expect { subject.execute }.to change { Profile::ProfileItem.count }.by(0)
          expect(subject.errors.full_messages).to include("An error")
        end
      end

      context "when there are errors copying the profile text" do
        before do
          errors = ActiveModel::Errors.new(profile_item)
          errors.add(:base, "An error")
          allow_any_instance_of(Profile::ProfileText).to receive(:save).and_return(errors)
          allow_any_instance_of(Profile::ProfileText).to receive(:errors).and_return(errors)
        end

        it "rolls back the transaction and returns errors" do
          expect { subject.execute }.to change { Profile::ProfileText.count }.by(0)
          expect(subject.errors.full_messages).to include("An error")
        end
      end

      context "when there are errors copying the profile item annotation" do
        before do
          errors = ActiveModel::Errors.new(profile_item_annotation)
          errors.add(:base, "An error")
          allow_any_instance_of(Profile::ProfileItemAnnotation).to receive(:save).and_return(errors)
          allow_any_instance_of(Profile::ProfileItemAnnotation).to receive(:errors).and_return(errors)
        end

        it "rolls back the transaction and returns errors" do
          expect { subject.execute }.to change { Profile::ProfileItemAnnotation.count }.by(0)
          expect(subject.errors.full_messages).to include("An error")
        end
      end

      context "when there are errors copying the profile item references" do
        before do
          errors = ActiveModel::Errors.new(profile_item_reference)
          errors.add(:base, "An error")
          allow_any_instance_of(Profile::ProfileItemReference).to receive(:save).and_return(errors)
          allow_any_instance_of(Profile::ProfileItemReference).to receive(:errors).and_return(errors)
        end

        it "rolls back the transaction and returns errors" do
          expect { subject.execute }.to change { Profile::ProfileItemReference.count }.by(0)
          expect(subject.errors.full_messages).to include("An error")
        end
      end
    end

    context "when profile item is a draft" do
      let(:profile_item) { create(:profile_item, instance: instance, product_item_config: product_item_config, is_draft: true) }

      it "does not create a new version and adds an error" do
        subject.execute
        expect(subject.errors.full_messages).to include("Profile item must be published before creating a new version")
      end
    end

    context "when a draft already exists for the product item config" do
      before do
        create(:profile_item, instance: instance, product_item_config: product_item_config, is_draft: true)
      end

      it "does not create a new version and adds an error" do
        subject.execute
        expect(subject.errors.full_messages).to include("There is still a draft profile item for this product item config")
      end
    end
  end
end
