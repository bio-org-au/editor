FactoryBot.define do
  factory :resource_type do
    lock_version { 1 }
    deprecated { true }
    description { "Sample Description" }
    display { true }
    name { "Sample Name" }
    rdf_id { "Sample Rdf" }
  end
end
