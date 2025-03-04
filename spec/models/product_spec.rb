require 'rails_helper'

RSpec.describe Product, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:tree).optional }
    it { is_expected.to belong_to(:reference).optional }
    it { is_expected.to have_many(:user_product_roles).class_name('User::ProductRole').with_foreign_key('product_id') }
    it { is_expected.to have_many(:product_contexts).class_name('Product::Context').with_foreign_key('product_id') }
  end
end
