require 'rails_helper'

describe ProfileItems::Published::MarkPublishService do
  let!(:user) { create(:user) }
  let!(:instance) { create(:instance, draft: false) }
  let!(:product_item_config) { create(:product_item_config) }

  subject do
    described_class.new(
      user: user,
      profile_item: profile_item,
      params: {}
    )
  end

  describe '#execute' do
    context 'when profile item is not a draft version' do
      let!(:instance) { create(:instance, draft: true) }
      let(:profile_item) { create(:profile_item, :draft, instance:, product_item_config:) }

      it 'adds an error and does not publish' do
        subject.execute
        expect(subject.errors[:base]).to include('Profile item must be a draft version of a published item')
        expect(profile_item.reload.is_draft).to be_truthy
      end
    end

    context 'when profile item is already published' do
      let!(:tree_element) { create(:tree_element, instance:, name: instance.name) }
      let!(:profile_item) { create(:profile_item, :published, instance:, product_item_config:, tree_element_id: tree_element.id) }

      it 'adds an error and does not publish' do
        subject.execute
        expect(subject.errors[:base]).to include('Profile item is already published')
      end
    end

    context 'when profile item can be published' do
      let!(:previous_published) { create(:profile_item, :published, instance:, product_item_config:, published_date: 2.days.ago) }
      let!(:profile_item) { create(:profile_item, :draft, created_by: "testuser", updated_by: "testuser", instance:, product_item_config:) }

      it 'publishes the profile item and updates previous published item' do
        subject.execute
        expect(subject.errors).to be_empty
        profile_item.reload
        expect(profile_item.is_draft).to be_falsey
        expect(profile_item.published_date).to be_within(1.second).of(Time.current)
        expect(profile_item.created_by).to eq("testuser")
        expect(profile_item.updated_by).to eq(user.user_name)
        expect(previous_published.reload.end_date).to be_within(1.second).of(profile_item.published_date)
      end

      it 'does not set end_date on the profile item being published' do
        subject.execute
        profile_item.reload
        expect(profile_item.end_date).to be_nil
      end
    end

    context 'when there is no previous published profile item' do
      let!(:profile_item) { create(:profile_item, :draft, created_by: "testuser", updated_by: "testuser", instance:, product_item_config:) }

      it 'publishes the profile item without errors' do
        subject.execute
        expect(subject.errors).to be_empty
        profile_item.reload
        expect(profile_item.is_draft).to be_falsey
        expect(profile_item.published_date).to be_within(1.second).of(Time.current)
        expect(profile_item.end_date).to be_nil
      end
    end

    context 'when previous published items exist for a different instance' do
      let!(:other_instance) { create(:instance, draft: false) }
      let!(:other_instance_published) { create(:profile_item, :published, instance: other_instance, product_item_config:, published_date: 2.days.ago) }
      let!(:profile_item) { create(:profile_item, :draft, created_by: "testuser", updated_by: "testuser", instance:, product_item_config:) }

      it 'does not update the end_date of a profile item belonging to a different instance' do
        expect { subject.execute }.not_to change { other_instance_published.reload.end_date }
        expect(subject.errors).to be_empty
      end
    end

    context 'when multiple previous published items exist for the same instance' do
      let!(:older_published) { create(:profile_item, :published, instance:, product_item_config:, published_date: 5.days.ago) }
      let!(:newer_published) { create(:profile_item, :published, instance:, product_item_config:, published_date: 2.days.ago) }
      let!(:profile_item) { create(:profile_item, :draft, created_by: "testuser", updated_by: "testuser", instance:, product_item_config:) }

      it 'updates end_date only on the most recently published item' do
        subject.execute
        expect(subject.errors).to be_empty
        expect(newer_published.reload.end_date).to be_within(1.second).of(profile_item.reload.published_date)
        expect { subject.execute }.not_to change { older_published.reload.end_date }
      end
    end

    context 'when publish_profile_item fails' do
      let!(:profile_item) { create(:profile_item, :draft, instance:, product_item_config:) }

      before do
        allow(profile_item).to receive(:save) do
          profile_item.errors.add(:base, "Save failed")
          false
        end
      end

      it 'rolls back the transaction and returns errors' do
        subject.execute
        expect(subject.errors.full_messages).to include("Save failed")
        expect(profile_item.reload.is_draft).to be_truthy
      end
    end

    context 'when update_previous_profile_item fails' do
      let!(:previous_published) { create(:profile_item, :published, instance:, product_item_config:, published_date: 2.days.ago) }
      let!(:profile_item) { create(:profile_item, :draft, created_by: "testuser", updated_by: "testuser", instance:, product_item_config:) }

      before do
        allow_any_instance_of(Profile::ProfileItem).to receive(:update).and_wrap_original do |method, *args|
          method.receiver.errors.add(:base, "Update failed")
          false
        end
      end

      it 'rolls back the transaction and returns errors' do
        subject.execute
        expect(subject.errors.full_messages).to include("Update failed")
      end
    end
  end
end
