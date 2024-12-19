FactoryBot.define do
  factory :name_group do
    sequence(:name) {|n| "Sample Name #{n}" }
    rdf_id { "Sample Rdf" }
  end
end
