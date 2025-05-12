# == Schema Information
#
# Table name: product_role
#
#  id           :bigint           not null, primary key
#  created_by   :string(50)       not null
#  deprecated   :boolean          default(FALSE), not null
#  lock_version :bigint           default(0), not null
#  updated_by   :string(50)       not null
#  created_at   :timestamptz      not null
#  updated_at   :timestamptz      not null
#  product_id   :bigint           not null
#  role_id      :bigint           not null
#
# Indexes
#
#  pr_unique_product_role  (product_id,role_id) UNIQUE
#
# Foreign Keys
#
#  pr_product_fk  (product_id => product.id)
#  pr_role_fk     (role_id => roles.id)
#
FactoryBot.define do
  factory :product_role, class: "Product::Role" do
    created_by { "fred" }
    updated_by { "fred" }

    association :product
    association :role
  end
end
