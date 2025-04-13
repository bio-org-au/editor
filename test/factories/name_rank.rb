# == Schema Information
#
# Table name: name_rank
#
#  id                :bigint           not null, primary key
#  abbrev            :string(20)       not null
#  deprecated        :boolean          default(FALSE), not null
#  description_html  :text
#  display_name      :text             not null
#  has_parent        :boolean          default(FALSE), not null
#  italicize         :boolean          default(FALSE), not null
#  lock_version      :bigint           default(0), not null
#  major             :boolean          default(FALSE), not null
#  name              :string(50)       not null
#  sort_order        :integer          default(0), not null
#  use_verbatim_rank :boolean          default(FALSE), not null
#  visible_in_name   :boolean          default(TRUE), not null
#  name_group_id     :bigint           not null
#  parent_rank_id    :bigint
#  rdf_id            :string(50)
#
# Indexes
#
#  name_rank_rdfid  (rdf_id)
#  nr_unique_name   (name_group_id,name) UNIQUE
#
# Foreign Keys
#
#  fk_p3lpayfbl9s3hshhoycfj82b9  (name_group_id => name_group.id)
#  fk_r67um91pujyfrx7h1cifs3cmb  (parent_rank_id => name_rank.id)
#
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
