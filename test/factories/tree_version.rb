FactoryBot.define do
  factory :tree_version do
    lock_version { 1 }
    created_by { "Sample Created by" }
    draft_name { "Sample Draft name" }
    published { true }
    published_by { "Sample Published by" }
    tree_id { 1 }
  end
end
