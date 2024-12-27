FactoryBot.define do
  factory :instance_note_key do
    lock_version { 1 }
    deprecated { true }
    name { "Sample Name" }
    sort_order { 1 }
    rdf_id { "Sample Rdf" }
  end
end
