FactoryBot.define do
  factory :profile_object_type, class: "Profile::ProfileObjectType" do
    name { "Sample Name" }
    rdf_id { "text" }
    is_deprecated { true }
    lock_version { 1 }
    created_by { "Sample Created by" }
    updated_by { "Sample Updated by" }
    api_name { "Sample Api name" }
    api_date { Time.current }
  end
end
