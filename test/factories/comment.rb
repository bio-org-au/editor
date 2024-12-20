FactoryBot.define do
  factory :comment do
    lock_version { 1 }
    created_by { "Sample Created by" }
    text { "Sample Text" }
    updated_by { "Sample Updated by" }
  end
end
