require 'rails_helper'

RSpec.describe User::ProductContext, type: :model do

  subject { described_class.new }

  describe "associations" do
    it { is_expected.to belong_to(:user).with_foreign_key('user_id') }
  end

  describe 'validations' do
    it "validates presence of context_id" do
      expect(subject).not_to be_valid
      expect(subject.errors.messages[:context_id]).to include("can't be blank")
    end

    it "validates presence of created_by" do
      expect(subject).not_to be_valid
      expect(subject.errors.messages[:created_by]).to include("can't be blank")
    end

    it "validates presence of updated_by" do
      expect(subject).not_to be_valid
      expect(subject.errors.messages[:updated_by]).to include("can't be blank")
    end
  end

  describe "#products" do
    let(:product) { FactoryBot.create(:product) }
    let(:product_context) { FactoryBot.create(:product_context, product: product) }

    subject { FactoryBot.create(:user_product_context, is_default: true, context_id: product_context.context_id) }

    it "returns the products associated to the context" do
      expect(subject.products).to eq([product])
    end
  end
end
