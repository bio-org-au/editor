require 'rails_helper'

RSpec.describe ProfileItems::Links::UpdateService, type: :service do
  let!(:instance) { create(:instance, name:) }

  let(:profile_text) { create(:profile_text) }
  let!(:product_item_config) { create(:product_item_config) }
  let!(:source_profile_item) do
    build(:profile_item,
      instance_id: instance.id,
      product_item_config:,
      profile_text:,
      statement_type: 'fact',
      is_draft: false
    )
  end

  let!(:profile_item) do
    create(:profile_item,
      product_item_config:,
      instance_id: instance.id,
      profile_text_id: profile_text.id,
      source_profile_item_id: source_profile_item.id,
      statement_type: 'link'
    )
  end

  let!(:name) { create(:name) }
  let!(:user) { create(:user) }
  let(:params) { {} }

  let(:service) { described_class.new(user: user, profile_item: profile_item, params: params) }

  describe '#execute' do
    context 'when the profile item is a draft' do
      it 'updates the profile item and creates a profile text' do
        expect { service.execute }.to change { Profile::ProfileText.count }.by(1)

        new_profile_text = Profile::ProfileText.last
        expect(profile_item.reload.profile_text_id).to eq(new_profile_text.id)
        expect(new_profile_text.value_md).to eq(profile_text.value_md)
        expect(new_profile_text.value).to eq(profile_text.value)
        expect(new_profile_text.created_by).to eq(user.user_name)
        expect(new_profile_text.updated_by).to eq(user.user_name)

        expect(profile_item.statement_type).to eq(Profile::ProfileItem::STATEMENT_TYPES[:fact])
        expect(profile_item.source_profile_item_id).to be_nil
        expect(profile_item.updated_by).to eq(user.user_name)
      end
    end

    context "when profile item's source has profile item references" do
      let!(:source_profile_item) do
        create(:profile_item,
          instance_id: instance.id,
          product_item_config:,
          profile_text:,
          statement_type: 'fact',
          is_draft: false
        )
      end

      let!(:reference1) { create(:profile_item_reference, profile_item: source_profile_item) }
      let!(:reference2) { create(:profile_item_reference, profile_item: source_profile_item) }

      it 'create a copy of the profile item references to the profile_item' do
        expect { service.execute }.to change { Profile::ProfileItemReference.count }.by(2)

        new_refs = Profile::ProfileItemReference.where(profile_item_id: profile_item.id)
        expect(new_refs.count).to eq(2)
        expect(new_refs.pluck(:reference_id)).to match_array([reference1.reference_id, reference2.reference_id])
        expect(new_refs.pluck(:created_by)).to all(eq(user.user_name))
        expect(new_refs.pluck(:updated_by)).to all(eq(user.user_name))
        expect(new_refs.pluck(:annotation)).to all(eq("Modified from."))
      end
    end

    context 'when the profile item is not a draft' do
      before { profile_item.update(is_draft: false) }

      it 'does not update the profile item and adds an error' do
        expect { service.execute }.not_to change { Profile::ProfileText.count }
        expect(service.errors[:base]).to include("Cannot update a published profile item")
      end
    end

    context 'when invalid' do
      before { allow(service).to receive(:valid?).and_return(false) }

      it 'does not perform any updates' do
        expect { service.execute }.not_to change { Profile::ProfileText.count }
        expect(profile_item.reload.profile_text_id).to eq(profile_text.id)
      end
    end

    context "when there are error saving the profile text" do
      before do
        errors = ActiveModel::Errors.new(profile_text)
        errors.add(:base, "An error")
        allow_any_instance_of(Profile::ProfileText).to receive(:save).and_return(errors)
        allow_any_instance_of(Profile::ProfileText).to receive(:errors).and_return(errors)
      end

      it "does not update the profile item" do
        service.execute
        expect(service.errors[:base]).to include("An error")
        expect(profile_item.reload.profile_text_id).to eq(profile_text.id)
      end
    end

    context "when there are errors saving the profile item" do
      let!(:source_profile_item) do
        create(:profile_item,
          instance_id: instance.id,
          product_item_config:,
          profile_text:,
          statement_type: 'fact',
          is_draft: false
        )
      end

      before do
        errors = ActiveModel::Errors.new(profile_item)
        errors.add(:base, "An error")
        allow_any_instance_of(Profile::ProfileItem).to receive(:save).and_return(errors)
        allow_any_instance_of(Profile::ProfileItem).to receive(:errors).and_return(errors)
      end

      it "does not update the profile item" do
        expect { service.execute }.to change { Profile::ProfileText.count }.by(0)
        expect(profile_item.reload.profile_text_id).to eq(profile_text.id)
        expect(profile_item.source_profile_item_id).not_to eq(nil)
        expect(service.errors[:base]).to include("An error")
      end
    end
  end

  describe '#draft_profile_item' do
    context 'when the profile item is a draft' do
      it 'does not add any errors' do
        service.send(:draft_profile_item)
        expect(service.errors).to be_empty
      end
    end

    context 'when the profile item is not a draft' do
      before { profile_item.update(is_draft: false) }

      it 'adds an error to the service' do
        service.send(:draft_profile_item)
        expect(service.errors[:base]).to include("Cannot update a published profile item")
      end
    end
  end
end
