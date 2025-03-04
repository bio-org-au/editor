require 'rails_helper'

RSpec.describe User, type: :model do

  describe "associations" do
    it { is_expected.to have_many(:batch_reviewers).class_name('Loader::Batch::Reviewer').with_foreign_key('user_id') }
    it { is_expected.to have_many(:product_roles).class_name('User::ProductRole').with_foreign_key('user_id') }
    it { is_expected.to have_many(:products).through(:product_roles) }
    it { is_expected.to have_many(:product_contexts).class_name('User::ProductContext').with_foreign_key('user_id') }
  end

  describe '#is?' do
    let(:user) { FactoryBot.create(:user) }
    let(:role_type) { FactoryBot.create(:role_type, name: 'admin') }
    let(:product) { FactoryBot.create(:product) }
    let!(:product_role) { FactoryBot.create(:user_product_role, user: user, role_type: role_type, product: product) }

    context 'when the user has the requested role type' do
      it 'returns true' do
        expect(user.is?('admin')).to be true
      end
    end

    context 'when the user does not have the requested role type' do
      it 'returns false' do
        expect(user.is?('editor')).to be false
      end
    end
  end
end
