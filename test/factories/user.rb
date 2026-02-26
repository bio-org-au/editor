FactoryBot.define do
  factory :user do
    sequence(:user_name) { |n| "sample name #{n}" }
    given_name { "Sample Given name" }
    family_name { "Sample Family name" }
    lock_version { 1 }
    created_by { "Sample Created by" }
    updated_by { "Sample Updated by" }
    default_product_context_id { nil }
  end
end
