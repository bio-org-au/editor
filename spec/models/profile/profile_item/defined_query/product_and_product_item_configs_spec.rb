require 'rails_helper'

RSpec.describe Profile::ProfileItem::DefinedQuery::ProductAndProductItemConfigs, type: :model do
  let(:session_user) { FactoryBot.create(:session_user) }
  let!(:user) { FactoryBot.create(:user, user_name: session_user.username) }
  let(:instance) { FactoryBot.create(:instance) }
  let(:params) { {} }

  subject { described_class.new(session_user, instance, params)}

  describe ".initialize" do
    it { should respond_to(:product) }
    it { should respond_to(:instance) }
    it { should respond_to(:product_configs_and_profile_items) }

    it "has instance variable session_user" do
      expect(subject.instance_variable_get(:@session_user)).to eq session_user
    end

    it "has instance variable user" do
      expect(subject.instance_variable_get(:@user)).to eq user
    end

    it "has instance variable profile_context" do
      expect(subject.instance_variable_get(:@profile_context).class).to eq Users::ProfileContexts::Apni
    end

    it "has instance variable product" do
      product = instance_double("Product")
      allow_any_instance_of(described_class).to receive(:find_product_by_name).and_return(product)
      expect(subject.instance_variable_get(:@product)).to eq product
    end

    it "has instance variable instance" do
      expect(subject.instance_variable_get(:@instance)).to eq instance
    end

    it "has instance variable params" do
      expect(subject.instance_variable_get(:@params)).to eq params
    end
  end

  describe "#run_query" do
    subject {described_class.new(session_user, instance, params).run_query}

    context "when profile_v2_aware config is enabled" do
      context "when there is no product" do
        it "returns an array of product_configs_and_profile_items and product" do
          expect(subject).to eq([[],nil])
        end
      end

      context "whern there is no instance" do
        let(:instance) { nil }
        it "returns an array of product_configs_and_profile_items and product" do
          expect(subject).to eq([[],nil])
        end
      end

      context "when there is a product" do
        let(:session_user) { FactoryBot.create(:session_user, :foa) }
        let!(:profile_product) { FactoryBot.create(:profile_product, name: "FOA") }
        context "and the product is not attached to a product_item_config" do
          it "returns an empty array of product_configs_and_profile_items and product" do
            expect(subject).to eq([[],profile_product])
          end
        end
        context "and a product is attached to a product_item_config" do
          let(:product_item_config) { FactoryBot.create(:product_item_config, product: profile_product) }
          it "returns an array of product_configs_and_profile_items and product" do
            profile_item = double("ProfileItem")
            allow(Profile::ProfileItem).to receive(:new).and_return(profile_item)
            result = [
              [{product_item_config: product_item_config, profile_item: profile_item}],
              profile_product
            ]

            expect(subject).to eq(result)
          end
        end
      end

      context "when a user has a FOA product role" do
        let(:product) { FactoryBot.create(:product, name: "FOA") }
        let!(:role) { FactoryBot.create(:role) }
        let!(:user_draft_profile_editor) { FactoryBot.create(:user_product_role, role:, user:, product:)}

        it "returns the product attached to the role" do
          expect(subject[1].id).to eq product.id
        end
      end
    end

    context "when profile_v2_aware config is disabled" do
      before {allow(Rails.configuration).to receive(:try).with('profile_v2_aware').and_return(false) }

      context "when there is no product" do
        it "returns an array of product_configs_and_profile_items and product" do
          expect(subject).to eq([[],nil])
        end
      end

      context "whern there is no instance" do
        let(:instance) { nil }
        it "returns an array of product_configs_and_profile_items and product" do
          expect(subject).to eq([[],nil])
        end
      end

      context "when there is a product" do
        let!(:session_user) { FactoryBot.create(:session_user, :foa) }
        let!(:profile_product) { FactoryBot.create(:profile_product, name: "FOA") }

        context "and the product is not attached to a product_item_config" do
          it "returns an empty array of product_configs_and_profile_items and product" do
            expect(subject).to eq([[],nil])
          end
        end
        context "and a product is attached to a product_item_config" do
          let!(:product_item_config) { FactoryBot.create(:product_item_config, product: profile_product) }
          it "returns an array of product_configs_and_profile_items and product" do
            expect(subject).to eq([[],nil])
          end
        end
      end
    end
  end
end
