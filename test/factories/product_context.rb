FactoryBot.define do
  factory :product_context, class: "Product::Context" do
    sequence(:context_id) {|n| n+1 }
    created_by { "fred" }
    updated_by { "fred" }

    association :product
  end
end
