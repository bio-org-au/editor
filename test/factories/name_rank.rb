FactoryBot.define do
  factory :name_rank do
    lock_version { 1 }
    abbrev { "Sample Abbrev" }
    deprecated { true }
    has_parent { true }
    italicize { true }
    major { true }
    sequence(:name) {|n| "Familia" }
    sort_order { 1 }
    visible_in_name { true }
    rdf_id { "Sample Rdf" }
    use_verbatim_rank { true }
    display_name { "Familia" }

    association :name_group
  end
end
