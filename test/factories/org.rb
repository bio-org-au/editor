FactoryBot.define do
  factory :org do
    name { "Sample Name" }
    abbrev { "Sample Abbrev" }
    deprecated { true }
    not_a_real_org { true }
    lock_version { 1 }
    created_by { "Sample Created by" }
    updated_by { "Sample Updated by" }
    can_vote { true }
  end
end
