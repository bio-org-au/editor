FactoryBot.define do
  factory :name_type do
    lock_version { 1 }
    autonym { true }
    cultivar { true }
    formula { true }
    hybrid { false }
    #sequence(:name) {|n| "Sample Name #{n}" }
    name { "phrase name" }
    scientific { false }
    sort_order { 1 }
    rdf_id { "Sample Rdf" }
    deprecated { false }
    vernacular { true }

    association :name_group
    association :name_category
  end
end
