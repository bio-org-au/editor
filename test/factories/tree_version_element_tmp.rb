FactoryBot.define do
  factory :tree_version_element_tmp do
    updated_by { "Sample Updated by" }
    merge_conflict { true }
  end
end
