FactoryBot.define do
  factory :product, class: "Profile::Product" do
    name { "Sample Name" }
    is_current { true }
    is_available { true }
    source_system { "Sample Source system" }
    source_id_string { "Sample Source id string" }
    lock_version { 1 }
    created_by { "Sample Created by" }
    updated_by { "Sample Updated by" }
    api_name { "Sample Api name" }
    api_date { Time.current }
  end
end
