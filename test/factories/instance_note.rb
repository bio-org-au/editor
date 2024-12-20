FactoryBot.define do
  factory :instance_note do
    lock_version { 1 }
    created_by { "Sample Created by" }
    instance_id { 1 }
    instance_note_key_id { 1 }
    namespace_id { 1 }
    source_id_string { "Sample Source id string" }
    source_system { "Sample Source system" }
    updated_by { "Sample Updated by" }
    value { "Sample Value" }
  end
end
