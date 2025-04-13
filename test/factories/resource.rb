FactoryBot.define do
  factory :resource do
    lock_version { 1 }
    created_by { "Sample Created by" }
    path { "Sample Path" }
    site_id { 1 }
    updated_by { "Sample Updated by" }
    resource_type_id { 1 }
  end
end
