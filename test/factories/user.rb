FactoryBot.define do
  factory :user do
    user_name { "Sample Name" }
    given_name { "Sample Given name" }
    family_name { "Sample Family name" }
    lock_version { 1 }
    created_by { "Sample Created by" }
    updated_by { "Sample Updated by" }
  end
end
