require 'rails_helper'

RSpec.describe Product::Context, type: :model do

  subject { described_class.new }

  describe "associations" do
    it { is_expected.to belong_to(:product).with_foreign_key('product_id') }
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
end
