FactoryBot.define do
  factory :profile_item, class: "Profile::ProfileItem" do
    instance_id { 1 }
    product_item_config_id { 1 }
    profile_object_rdf_id { "Sample Profile object rdf" }
    is_draft { true }
    published_date { Time.current }
    end_date { Time.current }
    statement_type { "fact" }
    is_object_type_reference { false }
    source_id_string { "Sample Source id string" }
    source_system { "Sample Source system" }
    lock_version { 1 }
    updated_by { "Sample Updated by" }
    created_by { "Sample Created by" }
    api_name { "Sample Api name" }
    api_date { Time.current }

    association :instance
    association :product_item_config
    association :profile_text
  end
end
