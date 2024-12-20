FactoryBot.define do
  factory :name_category do
    sort_order { 1 }
    rdf_id { "Sample Rdf" }
    max_parents_allowed { 1 }
    min_parents_required { 1 }
    requires_family { true }
    requires_higher_ranked_parent { true }
    requires_name_element { true }
    takes_author_only { true }
    takes_authors { true }
    takes_cultivar_scoped_parent { true }
    takes_hybrid_scoped_parent { true }
    takes_name_element { true }
    takes_verbatim_rank { true }
    takes_rank { true }

    transient do
      valid_names { ["phrase name"] }
    end
    sequence(:name) { |n| valid_names[n % valid_names.length] }
   
    initialize_with { NameCategory.find_or_create_by(name: name) }
  end
end
