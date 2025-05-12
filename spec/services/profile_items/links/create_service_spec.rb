require 'rails_helper'

RSpec.describe ProfileItems::Links::CreateService, type: :service do

  let(:instance) { FactoryBot.create(:instance, name:) }

  let(:profile_text) { FactoryBot.create(:profile_text) }
  let(:product_item_config) { FactoryBot.create(:product_item_config) }
  let(:source_profile_item) { FactoryBot.build(:profile_item, instance_id: instance.id, product_item_config: product_item_config, profile_text: profile_text, statement_type: 'fact', is_draft: false) }

  let(:name) { FactoryBot.create(:name) }

  let(:user) { FactoryBot.create(:user) }
  let(:params) { { key: "value" } }
  let(:service) { described_class.new(instance: instance, user: user, source_profile_item: source_profile_item, params: params) }

  describe "#initialize" do
    it "initializes with the correct attributes" do
      expect(service.instance_variable_get(:@instance)).to eq(instance)
      expect(service.instance_variable_get(:@user)).to eq(user)
      expect(service.instance_variable_get(:@source_profile_item)).to eq(source_profile_item)
      expect(service.instance_variable_get(:@params)).to eq(params)
    end

    it "initializes a new profile item with the correct attributes" do
      expect(service.profile_item).to be_a(Profile::ProfileItem)
      expect(service.profile_item.statement_type).to eq(Profile::ProfileItem::STATEMENT_TYPES[:link])
      expect(service.profile_item.source_profile_item_id).to eq(source_profile_item.id)
      expect(service.profile_item.is_draft).to be true
      expect(service.profile_item.instance_id).to eq(instance.id)
      expect(service.profile_item.profile_text_id).to eq(source_profile_item.profile_text_id)
      expect(service.profile_item.product_item_config_id).to eq(source_profile_item.product_item_config_id)
    end
  end

  describe "#execute" do
    context "when the service is valid" do
      it "creates a new profile item" do
        expect { service.execute }.to change(Profile::ProfileItem, :count).by(1)
      end

      it "assigns the correct attributes to the profile item" do
        service.execute
        profile_item = service.profile_item

        expect(profile_item.statement_type).to eq(Profile::ProfileItem::STATEMENT_TYPES[:link])
        expect(profile_item.source_profile_item_id).to eq(source_profile_item.id)
        expect(profile_item.is_draft).to be true
        expect(profile_item.instance_id).to eq(instance.id)
        expect(profile_item.profile_text_id).to eq(source_profile_item.profile_text_id)
        expect(profile_item.product_item_config_id).to eq(source_profile_item.product_item_config_id)
      end

      it "sets the current user on the profile item" do
        service.execute
        expect(service.profile_item.current_user).to eq(user)
      end
    end

    context "when the service is invalid" do
      let(:source_profile_item) { instance_double("Profile::ProfileItem", id: 1, profile_text_id: 1, product_item_config_id: 1, is_draft: true) }

      it "does not create a new profile item" do
        expect { service.execute }.not_to change(Profile::ProfileItem, :count)
      end

      it "adds an error to the service" do
        service.execute
        expect(service.errors[:base]).to include("Profile item must be published before linking")
      end
    end
  end
end
