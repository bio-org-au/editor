FactoryBot.define do
  factory :name do
    lock_version { 1 }
    created_by { "Sample Created by" }
    full_name { "Sample Full name" }
    full_name_html { "Sample Full name html" }
    name_element { "Sample Name element" }
    orth_var { true }
    simple_name { "Sample Simple name" }
    simple_name_html { "Sample Simple name html" }
    source_id_string { "Sample Source id string" }
    source_system { "Sample Source system" }
    status_summary { "Sample Status summary" }
    updated_by { "Sample Updated by" }
    valid_record { true }
    verbatim_rank { "Sample Verbatim rank" }
    sort_name { "Sample Sort name" }
    name_path { "Sample Name path" }
    changed_combination { true }

    association :namespace
    association :name_type
    association :name_status
    association :name_rank
  end
end
