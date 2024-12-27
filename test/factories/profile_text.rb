FactoryBot.define do
  factory :profile_text, class: "Profile::ProfileText" do
    value { "Sample Value" }
    source_system { "Sample Source system" }
    source_id_string { "Sample Source id string" }
    lock_version { 1 }
    created_by { "Sample Created by" }
    updated_by { "Sample Updated by" }
    api_name { "Sample Api name" }
    value_md { "Sample Value Md"}
    api_date { Time.current }
  end
end
