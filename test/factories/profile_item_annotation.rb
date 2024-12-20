FactoryBot.define do
  factory :profile_item_annotation, class: "Profile::ProfileItemAnnotation" do
    profile_item_id { 1 }
    value { "Sample Value" }
    source_id_string { "Sample Source id string" }
    lock_version { 1 }
    created_by { "Sample Created by" }
    updated_by { "Sample Updated by" }
    api_name { "Sample Api name" }
    api_date { Time.current }
  end
end
