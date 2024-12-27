FactoryBot.define do
  factory :author do
    lock_version { 1 }
    sequence(:abbrev) {|n| "Sample Abbrev #{n}" }
    created_by { "Sample Created by" }
    date_range { "Sample Date range" }
    full_name { "Sample Full name" }
    ipni_id { "Sample Ipni" }
    name { "Sample Name" }
    notes { "Sample Notes" }
    source_id_string { "Sample Source id string" }
    source_system { "Sample Source system" }
    updated_by { "Sample Updated by" }
    valid_record { true }
    sequence(:uri) {|n| "Sample Uri #{n}" }

    association :namespace
  end
end
