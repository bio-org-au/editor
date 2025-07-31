# == Schema Information
#
# Table name: tree
#
#  id                            :bigint           not null, primary key
#  accepted_tree                 :boolean          default(FALSE), not null
#  config                        :jsonb
#  description_html              :text             default("Edit me"), not null
#  full_name                     :text
#  group_name                    :text             not null
#  host_name                     :text             not null
#  is_read_only                  :boolean          default(FALSE)
#  is_schema                     :boolean          default(FALSE)
#  link_to_home_page             :text
#  lock_version                  :bigint           default(0), not null
#  name                          :text             not null
#  current_tree_version_id       :bigint
#  default_draft_tree_version_id :bigint
#  rdf_id                        :text             not null
#  reference_id                  :bigint
#
# Foreign Keys
#
#  fk_48skgw51tamg6ud4qa8oh0ycm  (default_draft_tree_version_id => tree_version.id)
#  fk_svg2ee45qvpomoer2otdc5oyc  (current_tree_version_id => tree_version.id)
#
FactoryBot.define do
  factory :tree do
    lock_version { 1 }
    accepted_tree { true }
    description_html { "Sample Description html" }
    group_name { "Sample Group name" }
    host_name { "Sample Host name" }
    name { "Sample Name" }
    rdf_id { "Sample Rdf" }
    is_schema { true }
    is_read_only { true }
  end
end
