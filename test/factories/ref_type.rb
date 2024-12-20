FactoryBot.define do
  factory :ref_type do
    lock_version { 1 }
    sequence(:name) {|n| "Sample Name #{n}" }
    parent_optional { true }
    rdf_id { "Sample Rdf" }
    use_parent_details { true }
  end
end
