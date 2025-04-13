# == Schema Information
#
# Table name: tree_version_element
#
#  depth           :integer          not null
#  element_link    :text             not null, primary key
#  merge_conflict  :boolean          default(FALSE), not null
#  name_path       :text             not null
#  taxon_link      :text             not null
#  tree_path       :text             not null
#  updated_by      :string(255)      not null
#  updated_at      :timestamptz      not null
#  parent_id       :text
#  taxon_id        :bigint           not null
#  tree_element_id :bigint           not null
#  tree_version_id :bigint           not null
#
# Indexes
#
#  tree_name_path_index                   (name_path)
#  tree_path_index                        (tree_path)
#  tree_version_element_element_index     (tree_element_id)
#  tree_version_element_link_index        (element_link)
#  tree_version_element_parent_index      (parent_id)
#  tree_version_element_taxon_id_index    (taxon_id)
#  tree_version_element_taxon_link_index  (taxon_link)
#  tree_version_element_version_index     (tree_version_id)
#
# Foreign Keys
#
#  fk_80khvm60q13xwqgpy43twlnoe  (tree_version_id => tree_version.id)
#  fk_8nnhwv8ldi9ppol6tg4uwn4qv  (parent_id => tree_version_element.element_link)
#  fk_ufme7yt6bqyf3uxvuvouowhh   (tree_element_id => tree_element.id)
#
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
