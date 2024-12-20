FactoryBot.define do
  factory :name_tag_name do
    name_id { 1 }
    tag_id { 1 }
    created_by { "Sample Created by" }
    updated_by { "Sample Updated by" }
  end
end
