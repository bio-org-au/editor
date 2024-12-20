FactoryBot.define do
  factory :profile_item_type, class: "Profile::ProfileItemType" do
    profile_object_type_id { 1 }
    name { "Sample Name" }
    rdf_id { "Sample Rdf" }
    is_deprecated { true }
    lock_version { 1 }
    created_by { "Sample Created by" }
    updated_by { "Sample Updated by" }
    api_name { "Sample Api name" }
    api_date { Time.current }
    sequence(:sort_order) {|n| n}

    association :profile_object_type
  end
end
