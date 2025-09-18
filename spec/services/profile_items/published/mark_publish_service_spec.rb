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
        expect(previous_published.end_date).to be_within(1.second).of(profile_item.published_date)
      end

    end
  end
end
