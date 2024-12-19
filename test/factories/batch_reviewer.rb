FactoryBot.define do
  factory :batch_reviewer do
    user_id { 1 }
    org_id { 1 }
    batch_review_role_id { 1 }
    batch_review_id { 1 }
    active { true }
    lock_version { 1 }
    created_by { "Sample Created by" }
    updated_by { "Sample Updated by" }
  end
end
