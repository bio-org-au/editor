# == Schema Information
#
# Table name: tree_element
#
#  id                  :bigint           not null, primary key
#  display_html        :text             not null
#  excluded            :boolean          default(FALSE), not null
#  instance_link       :text             not null
#  lock_version        :bigint           default(0), not null
#  name_element        :string(255)      not null
#  name_link           :text             not null
#  profile             :jsonb
#  rank                :string(50)       not null
#  simple_name         :text             not null
#  source_element_link :text
#  source_shard        :text             not null
#  synonyms            :jsonb
#  synonyms_html       :text             not null
#  updated_by          :string(255)      not null
#  updated_at          :timestamptz      not null
#  instance_id         :bigint           not null
#  name_id             :bigint           not null
#  previous_element_id :bigint
#
# Indexes
#
#  tree_element_instance_index  (instance_id)
#  tree_element_name_index      (name_id)
#  tree_element_previous_index  (previous_element_id)
#  tree_simple_name_index       (simple_name)
#  tree_synonyms_index          (synonyms) USING gin
#
# Foreign Keys
#
#  fk_5sv181ivf7oybb6hud16ptmo5  (previous_element_id => tree_element.id)
#
FactoryBot.define do
  factory :tree_element, class: "Tree::Element" do
    lock_version { 1 }
    display_html { "Sample Display html" }
    excluded { true }
    instance_id { 1 }
    instance_link { "Sample Instance link" }
    name_element { "Sample Name element" }
    name_id { 1 }
    name_link { "Sample Name link" }
    rank { "Sample Rank" }
    simple_name { "Sample Simple name" }
    source_shard { "Sample Source shard" }
    synonyms_html { "Sample Synonyms html" }
    updated_by { "Sample Updated by" }

    association :instance
    association :name
  end
end
