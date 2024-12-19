FactoryBot.define do
  factory :instance do
    lock_version { 1 }
    bhl_url { "Sample Bhl url" }
    created_by { "Sample Created by" }
    draft { true }
    nomenclatural_status { "Sample Nomenclatural status" }
    page { "Sample Page" }
    page_qualifier { "Sample Page qualifier" }
    reference_id { 1 }
    source_id_string { "Sample Source id string" }
    source_system { "Sample Source system" }
    updated_by { "Sample Updated by" }
    valid_record { true }
    verbatim_name_string { "Sample Verbatim name string" }
    uncited { true }

    association :namespace
    association :name
    association :reference
    association :instance_type
  end
end
