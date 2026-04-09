FactoryBot.define do
  factory :resource_type do
    lock_version { 1 }
    deprecated { true }
    description { "Sample Description" }
    display { true }
    sequence(:name) { |n| "Sample Name #{n}" }
    sequence(:rdf_id) { |n| "sample_rdf_#{n}" }
  end
end
