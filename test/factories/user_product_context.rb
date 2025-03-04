FactoryBot.define do
  factory :user_product_context, class: "User::ProductContext" do
    is_default { false }
    created_by { "fred" }
    updated_by { "fred" }
    sequence(:context_id) {|n| n+1 }

    association :user
  end
end
