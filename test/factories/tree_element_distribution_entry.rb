FactoryBot.define do
  factory :tree_element_distribution_entry do
    lock_version { 1 }
    dist_entry_id { 1 }
    tree_element_id { 1 }
    updated_by { "Sample Updated by" }
  end
end
