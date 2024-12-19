FactoryBot.define do
  factory :profile_item_reference, class: "Profile::ProfileItemReference" do
    profile_item_id { 1 }
    reference_id { 1 }
    created_by { "Sample Created by" }
    updated_by { "Sample Updated by" }
    lock_version { 1 }
    api_name { "Sample Api name" }
    api_date { Time.current }
  end
end
