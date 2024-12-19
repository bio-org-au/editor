FactoryBot.define do
  factory :tree_version_element do
    element_link { "Sample Element link" }
    depth { 1 }
    name_path { "Sample Name path" }
    taxon_id { 1 }
    taxon_link { "Sample Taxon link" }
    tree_element_id { 1 }
    tree_path { "Sample Tree path" }
    tree_version_id { 1 }
    updated_by { "Sample Updated by" }
    merge_conflict { true }
  end
end
