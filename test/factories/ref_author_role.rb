FactoryBot.define do
  factory :ref_author_role do
    lock_version { 1 }
    sequence(:name) {|n| "Sample Name #{n}" }
    rdf_id { "Sample Rdf" }
  end
end
