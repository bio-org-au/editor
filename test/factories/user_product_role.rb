# == Schema Information
#
# Table name: user_product_role
#
#  created_by      :string(50)       not null
#  lock_version    :bigint           default(0), not null
#  updated_by      :string(50)       not null
#  created_at      :timestamptz      not null
#  updated_at      :timestamptz      not null
#  product_role_id :bigint           not null
#  user_id         :bigint           not null, primary key
#
# Foreign Keys
#
#  upr_product_role_fk  (product_role_id => product_role.id)
#  upr_users_fk         (user_id => users.id)
#
FactoryBot.define do
  factory :user_product_role, class: "User::ProductRole" do
    created_by { "fred" }
    updated_by { "fred" }

    association :product_role
    association :user
  end
end
