FactoryBot.define do
  factory :role, class: "Role" do
    description { "Please describe this product role type" }
    sequence(:name) {|n| "role type #{n}" }
    created_by { "fred" }
    updated_by { "fred" }
  end
end
