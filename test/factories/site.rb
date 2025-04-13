FactoryBot.define do
  factory :site do
    lock_version { 1 }
    created_by { "Sample Created by" }
    description { "Sample Description" }
    name { "Sample Name" }
    updated_by { "Sample Updated by" }
    url { "Sample Url" }
  end
end
